clear; clc;

% ============================================================
% Export BFM L3b results: weakened visual observation rules
%
% L3b definition:
%   Priors and physical fault propagation rules remain complete.
%   Direct multimeter relations remain complete.
%   Visual symptom rules are weakened:
%
%       80% mass on the normal symptom relation
%       20% mass on full-frame ignorance
%
%   Weakened visual rules:
%       R_OPSU
%       R_I1 ... R_I8
%       R_OLa
%       R_OLi
%
%   Reliable measurement rules kept complete:
%       R_MB
%       R_MPS
%       R_M1 ... R_M8
%
% Real-life interpretation:
%   The company knows the circuit and component priors, but the mapping
%   from internal voltage states to visual symptoms may be unreliable.
%   LEDs may be damaged, dim, disconnected, misread, or poorly logged.
%
% Output:
%   runs/bfm_L3b_observation_rule_uncertainty_results.csv
% ============================================================

clearvars -global

if ~exist('runs', 'dir')
    mkdir('runs');
end

diary(fullfile('runs','export_bfm_L3b_observation_rule_uncertainty_diary.txt'));

disp('Exporting BFM L3b results: weakened visual observation rules');

global BELIEF VARIABLE ATTRIBUTE STRUCTURE FRAME QUERY BELTRACE
global NODE BJTREE TRANPROTOCOL;

% ------------------------------------------------------------
% Base L0 UIL
% ------------------------------------------------------------

l0_uil = fullfile('uilfiles','ten_cube_L0_complete_s8.txt');

if ~exist(l0_uil, 'file')
    error('Could not find L0 UIL file. Run run_10cube_L0_scenario8.m first.');
end

l3b_uil = fullfile('uilfiles','ten_cube_L3b_observation_rule_uncertainty.txt');
bm_file = 'bm_ten_cube_L3b_observation_rule_uncertainty';

% Observation-rule reliability
rule_reliability = 0.80;
rule_ignorance = 1 - rule_reliability;

% ------------------------------------------------------------
% Build L3b UIL
% ------------------------------------------------------------

txt = fileread(l0_uil);

% Weaken OPSU visual rule: Batt -> OPSU
txt = strrep(txt, ...
    'SET VALUATION R_OPSU {(good on) (exh off)} 1;', ...
    sprintf(['SET VALUATION R_OPSU {(good on) (exh off)} %.2f, ' ...
             '{(good on) (good off) (exh on) (exh off)} %.2f;'], ...
    rule_reliability, rule_ignorance));

% Weaken indicator rules: Vn -> In
for n = 1:8
    old_line = sprintf('SET VALUATION R_I%d {(v12 on) (v0 off)} 1;', n);

    new_line = sprintf(['SET VALUATION R_I%d {(v12 on) (v0 off)} %.2f, ' ...
                        '{(v12 on) (v12 off) (v0 on) (v0 off)} %.2f;'], ...
        n, rule_reliability, rule_ignorance);

    txt = strrep(txt, old_line, new_line);
end

% Weaken lamp rule: V8, CL, LF -> OLa
old_OLa = [
    "SET VALUATION R_OLa {" newline ...
    "(v12 ok ok on)" newline ...
    "(v12 ok bro off)" newline ...
    "(v12 bro ok off)" newline ...
    "(v12 bro bro off)" newline ...
    "(v0 ok ok off)" newline ...
    "(v0 ok bro off)" newline ...
    "(v0 bro ok off)" newline ...
    "(v0 bro bro off)" newline ...
    "} 1;"
];

full_OLa = [ ...
    "{(v12 ok ok on) (v12 ok ok off) " ...
    "(v12 ok bro on) (v12 ok bro off) " ...
    "(v12 bro ok on) (v12 bro ok off) " ...
    "(v12 bro bro on) (v12 bro bro off) " ...
    "(v0 ok ok on) (v0 ok ok off) " ...
    "(v0 ok bro on) (v0 ok bro off) " ...
    "(v0 bro ok on) (v0 bro ok off) " ...
    "(v0 bro bro on) (v0 bro bro off)}" ...
];

new_OLa = sprintf([ ...
    'SET VALUATION R_OLa {\n' ...
    '(v12 ok ok on)\n' ...
    '(v12 ok bro off)\n' ...
    '(v12 bro ok off)\n' ...
    '(v12 bro bro off)\n' ...
    '(v0 ok ok off)\n' ...
    '(v0 ok bro off)\n' ...
    '(v0 bro ok off)\n' ...
    '(v0 bro bro off)\n' ...
    '} %.2f, %s %.2f;'], ...
    rule_reliability, full_OLa, rule_ignorance);

txt = strrep(txt, char(old_OLa), new_OLa);

% Weaken lamp-indicator rule: V8, CL -> OLi
old_OLi = [
    "SET VALUATION R_OLi {" newline ...
    "(v12 ok on)" newline ...
    "(v12 bro off)" newline ...
    "(v0 ok off)" newline ...
    "(v0 bro off)" newline ...
    "} 1;"
];

full_OLi = [ ...
    "{(v12 ok on) (v12 ok off) " ...
    "(v12 bro on) (v12 bro off) " ...
    "(v0 ok on) (v0 ok off) " ...
    "(v0 bro on) (v0 bro off)}" ...
];

new_OLi = sprintf([ ...
    'SET VALUATION R_OLi {\n' ...
    '(v12 ok on)\n' ...
    '(v12 bro off)\n' ...
    '(v0 ok off)\n' ...
    '(v0 bro off)\n' ...
    '} %.2f, %s %.2f;'], ...
    rule_reliability, full_OLi, rule_ignorance);

txt = strrep(txt, char(old_OLi), new_OLi);

% Write L3b UIL
fid = fopen(l3b_uil, 'w');
if fid == -1
    error('Could not open L3b UIL for writing.');
end
fprintf(fid, '%s', txt);
fclose(fid);

disp(['L3b UIL written to: ', l3b_uil]);

% ------------------------------------------------------------
% Convert and load L3b BFM model
% ------------------------------------------------------------

disp('Converting L3b UIL to BFM model...');
uil2bm(l3b_uil, bm_file);

if ~exist([bm_file '.mat'], 'file')
    error(['uil2bm did not create ', bm_file, '.mat. Check UIL syntax above.']);
end

disp('Loading L3b BFM model...');
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

rows = {};

% ------------------------------------------------------------
% Run all scenarios
% ------------------------------------------------------------

for s_idx = 1:length(scenario_ids)

    scenario_id = scenario_ids(s_idx);

    fprintf('\n============================================================\n');
    fprintf('Scenario %d - L3b weakened visual observation rules\n', scenario_id);
    fprintf('============================================================\n');

    obs = make_scenario_observations(scenario_id);

    disp('Hard evidence used with weakened observation rules:');
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
            'L3b_observation_rule_uncertainty', ...
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

    T_s = cell2table(scenario_rows, ...
        'VariableNames', {'scenario_id','level','bn_fault_var','bn_fault_state', ...
                          'bfm_var','bfm_fault_state','belief','plausibility', ...
                          'width','empty_set_mass'});

    % Rank by belief: direct committed support
    [~, order_belief] = sortrows([-T_s.belief, -T_s.plausibility]);
    rank_by_belief = zeros(height(T_s), 1);
    rank_by_belief(order_belief) = (1:height(T_s))';
    T_s.rank_by_belief = rank_by_belief;

    % Rank by plausibility: not ruled out / still possible
    [~, order_plaus] = sortrows([-T_s.plausibility, -T_s.belief]);
    rank_by_plausibility = zeros(height(T_s), 1);
    rank_by_plausibility(order_plaus) = (1:height(T_s))';
    T_s.rank_by_plausibility = rank_by_plausibility;

    T_s = sortrows(T_s, {'rank_by_belief'});

    for r = 1:height(T_s)
        rows(end+1, :) = table2cell(T_s(r, :));
    end

end

% ------------------------------------------------------------
% Export final results
% ------------------------------------------------------------

T = cell2table(rows, ...
    'VariableNames', {'scenario_id','level','bn_fault_var','bn_fault_state', ...
                      'bfm_var','bfm_fault_state','belief','plausibility', ...
                      'width','empty_set_mass','rank_by_belief', ...
                      'rank_by_plausibility'});

out_path = fullfile('runs','bfm_L3b_observation_rule_uncertainty_results.csv');
writetable(T, out_path);

disp(['Saved BFM L3b results to: ', out_path]);

disp('Top 10 results per scenario by belief:');
for s_idx = 1:length(scenario_ids)
    scenario_id = scenario_ids(s_idx);
    disp(['Scenario ', num2str(scenario_id)]);
    disp(T(T.scenario_id == scenario_id & T.rank_by_belief <= 10, :));
end

disp('Top 10 results per scenario by plausibility:');
for s_idx = 1:length(scenario_ids)
    scenario_id = scenario_ids(s_idx);
    disp(['Scenario ', num2str(scenario_id)]);
    Ts = T(T.scenario_id == scenario_id, :);
    Ts = sortrows(Ts, {'rank_by_plausibility'});
    disp(Ts(1:min(10,height(Ts)), :));
end

save(fullfile('runs','export_bfm_L3b_observation_rule_uncertainty_workspace.mat'));

diary off;

% ============================================================
% Local helper function: scenario evidence
% ============================================================

function obs = make_scenario_observations(scenario_id)

    obs = [];

    switch scenario_id

        case 7
            obs(end+1) = observe('OPSU', 'off');

            for n = 1:8
                obs(end+1) = observe(sprintf('I%d', n), 'off');
            end

            obs(end+1) = observe('OLa', 'off');
            obs(end+1) = observe('OLi', 'off');
            obs(end+1) = observe('MB', 'v0');
            obs(end+1) = observe('MPS', 'high');

        case 8
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
            obs(end+1) = observe('OPSU', 'on');
            obs(end+1) = observe('OLa', 'off');
            obs(end+1) = observe('OLi', 'off');

        case 14
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

% ============================================================
% Local helper function: extract belief/plausibility
% ============================================================

function metrics = extract_binary_fault_metrics(result_belief_id, fault_state)

    tbl = showbel(result_belief_id);
    lines = cellstr(tbl);

    belief = 0;
    plausibility = 0;
    empty_mass = 0;

    current_states = {};
    current_raw_mass = NaN;
    current_norm_mass = NaN;

    for i = 1:length(lines)

        line = strtrim(lines{i});

        if isempty(line)
            continue;
        end

        if contains(line, 'value')
            continue;
        end

        if contains(line, '---')

            if ~isempty(current_states) || ~isnan(current_raw_mass) || ~isnan(current_norm_mass)

                [belief, plausibility, empty_mass] = process_focal_set( ...
                    current_states, current_raw_mass, current_norm_mass, ...
                    fault_state, belief, plausibility, empty_mass);

                current_states = {};
                current_raw_mass = NaN;
                current_norm_mass = NaN;
            end

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

        norm_value_str = '';
        if length(parts) >= 3
            norm_value_str = strtrim(parts{3});
        end

        raw_value = str2double(raw_value_str);
        norm_value = str2double(norm_value_str);

        if strcmp(state, '')
            if ~isnan(raw_value)
                current_states = {};
                current_raw_mass = raw_value;
                current_norm_mass = NaN;
            end
            continue;
        end

        current_states{end+1} = state;

        if ~isnan(raw_value)
            current_raw_mass = raw_value;
        end

        if ~isnan(norm_value)
            current_norm_mass = norm_value;
        end
    end

    if ~isempty(current_states) || ~isnan(current_raw_mass) || ~isnan(current_norm_mass)
        [belief, plausibility, empty_mass] = process_focal_set( ...
            current_states, current_raw_mass, current_norm_mass, ...
            fault_state, belief, plausibility, empty_mass);
    end

    metrics.belief = belief;
    metrics.plausibility = plausibility;
    metrics.width = plausibility - belief;
    metrics.empty_mass = empty_mass;

end


function [belief, plausibility, empty_mass] = process_focal_set( ...
    current_states, current_raw_mass, current_norm_mass, fault_state, ...
    belief, plausibility, empty_mass)

    if ~isnan(current_norm_mass)
        mass = current_norm_mass;
    elseif ~isnan(current_raw_mass)
        mass = current_raw_mass;
    else
        mass = NaN;
    end

    if isnan(mass)
        return;
    end

    if isempty(current_states)
        if ~isnan(current_raw_mass)
            empty_mass = current_raw_mass;
        end
        return;
    end

    if length(current_states) == 1 && all(current_states{1} == '*')
        plausibility = plausibility + mass;
        return;
    end

    contains_fault = any(strcmp(current_states, fault_state));

    if length(current_states) == 1 && contains_fault
        belief = belief + mass;
    end

    if contains_fault
        plausibility = plausibility + mass;
    end

end