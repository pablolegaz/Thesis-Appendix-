clear; clc;

% ============================================================
% Export BFM L0 results for thesis scenarios
%
% Uses the complete 10-cube BFM model already generated from:
%   uilfiles/ten_cube_L0_complete_s8.txt
%
% Scenarios are aligned with BN_V2_GOOD notebook:
%   S[7], S[8], S[11], S[14]
%
% Output:
%   runs/bfm_L0_results.csv
% ============================================================

if ~exist('runs', 'dir')
    mkdir('runs');
end

diary(fullfile('runs','export_bfm_L0_results_diary.txt'));

disp('Exporting BFM L0 results for scenarios 7, 8, 11, 14');

global BELIEF VARIABLE ATTRIBUTE STRUCTURE FRAME QUERY BELTRACE
global NODE BJTREE TRANPROTOCOL;

% ------------------------------------------------------------
% Load complete L0 BFM model
% ------------------------------------------------------------

bm_file = 'bm_ten_cube_L0_complete_s8';

if ~exist([bm_file '.mat'], 'file')
    error(['Could not find ', bm_file, '.mat. First run run_10cube_L0_scenario8.m once to generate the L0 model.']);
end

disp('Loading BFM L0 model...');
load(bm_file);

disp('Embedding conditional beliefs...');
embelall = condiembed([BELIEF(:).number]);

disp('Keeping embedded beliefs...');
keepbel(embelall);

disp(['Number of embedded beliefs: ', num2str(length(embelall))]);

% ------------------------------------------------------------
% Fault variable mapping: BFM names <-> official BN names
% ------------------------------------------------------------

fault_map = {
    'PSF',  'yes', 'F_PSU_short',  'yes';
    'Batt', 'exh', 'F_battery',    'exhausted';

    'SW1',  'det', 'F_sw_1',       'detached';
    'SW2',  'det', 'F_sw_2',       'detached';
    'SW3',  'det', 'F_sw_3',       'detached';
    'SW4',  'det', 'F_sw_4',       'detached';
    'SW5',  'det', 'F_sw_5',       'detached';
    'SW6',  'det', 'F_sw_6',       'detached';
    'SW7',  'det', 'F_sw_7',       'detached';
    'SW8',  'det', 'F_sw_8',       'detached';

    'C1',   'bro', 'F_cable_1',    'broken';
    'C2',   'bro', 'F_cable_2',    'broken';
    'C3',   'bro', 'F_cable_3',    'broken';
    'C4',   'bro', 'F_cable_4',    'broken';
    'C5',   'bro', 'F_cable_5',    'broken';
    'C6',   'bro', 'F_cable_6',    'broken';
    'C7',   'bro', 'F_cable_7',    'broken';
    'C8',   'bro', 'F_cable_8',    'broken';

    'CL',   'bro', 'F_cable_load', 'broken';
    'LF',   'bro', 'F_lamp',       'broken';
};

scenario_ids = [7, 8, 11, 14];

% Storage
rows = {};

% ------------------------------------------------------------
% Run scenarios
% ------------------------------------------------------------

for s_idx = 1:length(scenario_ids)

    scenario_id = scenario_ids(s_idx);

    fprintf('\n============================================================\n');
    fprintf('Scenario %d\n', scenario_id);
    fprintf('============================================================\n');

    obs = make_scenario_observations(scenario_id);

    disp('Evidence used:');
    showbel(obs);

    beliefs_with_evidence = [embelall obs];

    scenario_rows = {};

    for k = 1:size(fault_map, 1)

        bfm_var = fault_map{k, 1};
        bfm_fault_state = fault_map{k, 2};
        bn_fault_var = fault_map{k, 3};
        bn_fault_state = fault_map{k, 4};

        fprintf('Solving %s...\n', bfm_var);

        result = solve(beliefs_with_evidence, bfm_var);

        metrics = extract_binary_fault_metrics(result, bfm_fault_state);

        scenario_rows(end+1, :) = {
            scenario_id, ...
            'L0_complete', ...
            bn_fault_var, ...
            bn_fault_state, ...
            bfm_var, ...
            bfm_fault_state, ...
            metrics.belief, ...
            metrics.plausibility, ...
            metrics.width, ...
            metrics.empty_mass ...
        };

    end

    % Convert current scenario to table to rank by belief
    T_s = cell2table(scenario_rows, ...
        'VariableNames', {'scenario_id','level','bn_fault_var','bn_fault_state', ...
                          'bfm_var','bfm_fault_state','belief','plausibility', ...
                          'width','empty_set_mass'});

    T_s = sortrows(T_s, 'belief', 'descend');
    T_s.bfm_rank = (1:height(T_s))';

    % Append rows
    for r = 1:height(T_s)
        rows(end+1, :) = table2cell(T_s(r, :));
    end

end

% ------------------------------------------------------------
% Final table
% ------------------------------------------------------------

T = cell2table(rows, ...
    'VariableNames', {'scenario_id','level','bn_fault_var','bn_fault_state', ...
                      'bfm_var','bfm_fault_state','belief','plausibility', ...
                      'width','empty_set_mass','bfm_rank'});

out_path = fullfile('runs','bfm_L0_results.csv');
writetable(T, out_path);

disp(['Saved BFM L0 results to: ', out_path]);

disp('Top 10 results per scenario:');
for s_idx = 1:length(scenario_ids)
    scenario_id = scenario_ids(s_idx);
    disp(['Scenario ', num2str(scenario_id)]);
    disp(T(T.scenario_id == scenario_id & T.bfm_rank <= 10, :));
end

save(fullfile('runs','export_bfm_L0_results_workspace.mat'));

diary off;

% ============================================================
% Local functions
% ============================================================

function obs = make_scenario_observations(scenario_id)

    obs = [];

    switch scenario_id

        case 7
            % Matches BN_V2_GOOD S[7]
            obs(end+1) = observe('OPSU', 'off');

            for n = 1:8
                obs(end+1) = observe(sprintf('I%d', n), 'off');
            end

            obs(end+1) = observe('OLa', 'off');
            obs(end+1) = observe('OLi', 'off');
            obs(end+1) = observe('MB', 'v0');
            obs(end+1) = observe('MPS', 'high');

        case 8
            % Matches BN_V2_GOOD S[8]
            obs(end+1) = observe('OPSU', 'on');

            obs(end+1) = observe('I1', 'on');
            obs(end+1) = observe('I2', 'on');

            for n = 3:8
                obs(end+1) = observe(sprintf('I%d', n), 'off');
            end

            obs(end+1) = observe('OLa', 'off');
            obs(end+1) = observe('OLi', 'off');
            obs(end+1) = observe('MB', 'v12');
            obs(end+1) = observe('MPS', 'high');

        case 11
            % Matches BN_V2_GOOD S[11]
            obs(end+1) = observe('OPSU', 'on');
            obs(end+1) = observe('OLa', 'off');
            obs(end+1) = observe('OLi', 'off');

        case 14
            % Matches BN_V2_GOOD S[14]
            obs(end+1) = observe('OPSU', 'off');

            for n = 1:8
                obs(end+1) = observe(sprintf('I%d', n), 'off');
            end

            obs(end+1) = observe('OLa', 'off');
            obs(end+1) = observe('OLi', 'off');
            obs(end+1) = observe('MB', 'v0');
            obs(end+1) = observe('MPS', 'low');

        otherwise
            error(['Unknown scenario_id: ', num2str(scenario_id)]);
    end
end


function metrics = extract_binary_fault_metrics(result_belief_id, fault_state)

    % showbel returns a character array representation of the mass table.
    tbl = showbel(result_belief_id);
    lines = cellstr(tbl);

    fault_mass = 0;
    ignorance_mass = 0;
    empty_mass = 0;

    for i = 1:length(lines)

        line = strtrim(lines{i});

        if isempty(line)
            continue;
        end

        % Skip header/separators
        if contains(line, 'value') || contains(line, '---')
            continue;
        end

        if ~contains(line, '|')
            continue;
        end

        parts = split(line, '|');

        if length(parts) < 2
            continue;
        end

        state = strtrim(parts{1});
        raw_value_str = strtrim(parts{2});

        n_mass_str = '';
        if length(parts) >= 3
            n_mass_str = strtrim(parts{3});
        end

        raw_value = str2double(raw_value_str);
        n_mass = str2double(n_mass_str);

        if isnan(raw_value)
            raw_value = 0;
        end

        if isnan(n_mass)
            n_mass = raw_value;
        end

        % Empty state = conflict mass
        if strcmp(state, '')
            empty_mass = raw_value;
            continue;
        end

        % Full frame / ignorance
        if strcmp(state, '**')
            ignorance_mass = n_mass;
            continue;
        end

        % Fault state
        if strcmp(state, fault_state)
            fault_mass = n_mass;
            continue;
        end
    end

    metrics.belief = fault_mass;
    metrics.plausibility = fault_mass + ignorance_mass;
    metrics.width = ignorance_mass;
    metrics.empty_mass = empty_mass;
end