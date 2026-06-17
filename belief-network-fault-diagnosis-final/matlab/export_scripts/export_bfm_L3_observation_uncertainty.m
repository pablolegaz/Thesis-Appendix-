clear; clc;

% ============================================================
% Export BFM L3 results: observation uncertainty
%
% L3 definition:
%   Priors and physical structure remain complete.
%   Scenario evidence is no longer treated as perfectly reliable.
%
%   Each observed symptom/measurement is discounted:
%       80% mass on the observed value
%       20% mass on the full frame
%
% This represents realistic uncertainty in diagnostic observations:
%   - LED may be damaged or hard to read
%   - lamp indicator may be unreliable
%   - multimeter contact may be imperfect
%   - logs may contain uncertain observations
%
% Scenarios:
%   7, 8, 11, 14
%
% Output:
%   runs/bfm_L3_observation_uncertainty_results.csv
% ============================================================

clearvars -global

if ~exist('runs', 'dir')
    mkdir('runs');
end

diary(fullfile('runs','export_bfm_L3_observation_uncertainty_diary.txt'));

disp('Exporting BFM L3 results: observation uncertainty');

global BELIEF VARIABLE ATTRIBUTE STRUCTURE FRAME QUERY BELTRACE
global NODE BJTREE TRANPROTOCOL;

% ------------------------------------------------------------
% Load validated complete L0 BFM model
% ------------------------------------------------------------

bm_file = 'bm_ten_cube_L0_complete_s8';

if ~exist([bm_file '.mat'], 'file')
    error(['Could not find ', bm_file, '.mat. Run run_10cube_L0_scenario8.m first.']);
end

disp('Loading complete L0 BFM model...');
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

% Discount rate:
%   0.20 means 20% mass is moved to ignorance.
%   The observation still has 80% committed support.
obs_uncertainty = 0.20;

rows = {};

% ------------------------------------------------------------
% Run all scenarios
% ------------------------------------------------------------

for s_idx = 1:length(scenario_ids)

    scenario_id = scenario_ids(s_idx);

    fprintf('\n============================================================\n');
    fprintf('Scenario %d - L3 observation uncertainty\n', scenario_id);
    fprintf('============================================================\n');

    % Scenario evidence with discounted observations
    obs = make_scenario_observations_L3(scenario_id, obs_uncertainty);

    disp('Discounted evidence used:');
    showbel(obs);

    beliefs_with_evidence = [embelall obs];

    scenario_rows = {};

    % --------------------------------------------------------
    % Solve all fault variables
    % --------------------------------------------------------

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
            'L3_observation_uncertainty', ...
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

    % --------------------------------------------------------
    % Add rankings
    % --------------------------------------------------------

    % Rank by belief: direct committed support.
    % Tie-breaker: higher plausibility.
    [~, order_belief] = sortrows([-T_s.belief, -T_s.plausibility]);
    rank_by_belief = zeros(height(T_s), 1);
    rank_by_belief(order_belief) = (1:height(T_s))';
    T_s.rank_by_belief = rank_by_belief;

    % Rank by plausibility: still possible / not ruled out.
    % Tie-breaker: higher belief.
    [~, order_plaus] = sortrows([-T_s.plausibility, -T_s.belief]);
    rank_by_plausibility = zeros(height(T_s), 1);
    rank_by_plausibility(order_plaus) = (1:height(T_s))';
    T_s.rank_by_plausibility = rank_by_plausibility;

    % Sort for storage/display by belief rank
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

out_path = fullfile('runs','bfm_L3_observation_uncertainty_results.csv');
writetable(T, out_path);

disp(['Saved BFM L3 results to: ', out_path]);

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

save(fullfile('runs','export_bfm_L3_observation_uncertainty_workspace.mat'));

diary off;

% ============================================================
% Local helper function: scenario evidence with observation uncertainty
% ============================================================

function obs = make_scenario_observations_L3(scenario_id, discount_rate)

    obs = [];

    switch scenario_id

        case 7
            % Scenario 7: battery exhausted.
            % Available evidence is discounted to represent uncertain
            % LED/lamp/multimeter observations.
            obs(end+1) = soft_observe('OPSU', 'off', discount_rate);

            for n = 1:8
                obs(end+1) = soft_observe(sprintf('I%d', n), 'off', discount_rate);
            end

            obs(end+1) = soft_observe('OLa', 'off', discount_rate);
            obs(end+1) = soft_observe('OLi', 'off', discount_rate);
            obs(end+1) = soft_observe('MB', 'v0', discount_rate);
            obs(end+1) = soft_observe('MPS', 'high', discount_rate);

        case 8
            % Scenario 8: module-3 transition fault.
            % The control-chain observation pattern is discounted:
            % indicators 1-2 on, indicators 3-8 off, lamp off.
            obs(end+1) = soft_observe('OPSU', 'on', discount_rate);

            obs(end+1) = soft_observe('I1', 'on', discount_rate);
            obs(end+1) = soft_observe('I2', 'on', discount_rate);

            for n = 3:8
                obs(end+1) = soft_observe(sprintf('I%d', n), 'off', discount_rate);
            end

            obs(end+1) = soft_observe('OLa', 'off', discount_rate);
            obs(end+1) = soft_observe('OLi', 'off', discount_rate);
            obs(end+1) = soft_observe('MB', 'v12', discount_rate);
            obs(end+1) = soft_observe('MPS', 'high', discount_rate);

        case 11
            % Scenario 11: sparse evidence / no detailed tools.
            % This is the hardest observation-uncertainty case because
            % only three observations are available, and all are discounted.
            obs(end+1) = soft_observe('OPSU', 'on', discount_rate);
            obs(end+1) = soft_observe('OLa', 'off', discount_rate);
            obs(end+1) = soft_observe('OLi', 'off', discount_rate);

        case 14
            % Scenario 14: PSU short + battery discharged.
            % Direct upstream measurements are discounted rather than hard.
            obs(end+1) = soft_observe('OPSU', 'off', discount_rate);

            for n = 1:8
                obs(end+1) = soft_observe(sprintf('I%d', n), 'off', discount_rate);
            end

            obs(end+1) = soft_observe('OLa', 'off', discount_rate);
            obs(end+1) = soft_observe('OLi', 'off', discount_rate);
            obs(end+1) = soft_observe('MB', 'v0', discount_rate);
            obs(end+1) = soft_observe('MPS', 'low', discount_rate);

        otherwise
            error(['Unknown scenario_id: ', num2str(scenario_id)]);
    end
end


function belid = soft_observe(var_name, observed_value, discount_rate)

    % Create a hard observation, then discount it.
    % If discount_rate = 0.20:
    %   80% remains committed to observed_value
    %   20% is moved to the full frame / ignorance

    hard_belid = observe(var_name, observed_value);

    if discount_rate > 0
        soft_belid = discount(hard_belid, discount_rate);
        belid = soft_belid(1);
    else
        belid = hard_belid;
    end
end

% ============================================================
% Local helper function: extract belief/plausibility
% ============================================================

function metrics = extract_binary_fault_metrics(result_belief_id, fault_state)

    % Extract belief, plausibility, width, and empty-set conflict
    % from a BFM result for a binary fault variable.
    %
    % Handles:
    %   - singleton focal sets
    %   - empty-set conflict
    %   - full-frame ignorance printed as **, ****, ******, etc.
    %
    % Bel(fault_state) = mass assigned exactly to fault_state.
    % Pl(fault_state)  = mass assigned to any focal set compatible
    %                    with fault_state.
    %
    % For binary variables, full-frame ignorance contributes to
    % plausibility but not belief.

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

        % Empty-set conflict row: blank state with raw mass.
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

    % Flush final focal set
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

    % Empty set / conflict
    if isempty(current_states)
        if ~isnan(current_raw_mass)
            empty_mass = current_raw_mass;
        end
        return;
    end

    % Full-frame ignorance printed as **, ****, ******, etc.
    if length(current_states) == 1 && all(current_states{1} == '*')
        plausibility = plausibility + mass;
        return;
    end

    contains_fault = any(strcmp(current_states, fault_state));

    % Belief: focal set is exactly the fault state.
    if length(current_states) == 1 && contains_fault
        belief = belief + mass;
    end

    % Plausibility: focal set contains the fault state.
    if contains_fault
        plausibility = plausibility + mass;
    end

end