clear; clc;

% ============================================================
% Export BFM L4 results: combined incompleteness
%
% L4 definition:
%   Combined realistic diagnostic incompleteness:
%     1. A key discriminating observation is missing.
%     2. The relevant subsystem/fault-family priors are unknown.
%     3. Visual observation rules are weakened.
%
% Derived scenarios:
%
%   Scenario 15:
%     Battery discharge observed, PSU-short measurement unavailable.
%     Tests ambiguity between:
%       - battery-only exhaustion
%       - hidden PSU-short-induced battery discharge
%
%     Evidence:
%       OPSU = off
%       I1-I8 = off
%       OLa = off
%       OLi = off
%       MB = v0
%       MPS = missing
%
%     Missing/uncertain knowledge:
%       - PSF prior unknown
%       - battery conditional prior unknown
%       - visual symptom rules weakened
%
%   Scenario 16:
%     Module-3 transition fault, but boundary indicator I3 unavailable.
%     Tests whether localization remains physically constrained when the
%     key boundary observation is missing.
%
%     Evidence:
%       OPSU = on
%       I1 = on
%       I2 = on
%       I3 = missing
%       I4-I8 = off
%       OLa = off
%       OLi = off
%       MB = v12
%       MPS = high
%
%     Missing/uncertain knowledge:
%       - all switch/cable priors unknown
%       - visual symptom rules weakened
%
% Output:
%   runs/bfm_L4_combined_incompleteness_results.csv
% ============================================================

clearvars -global

if ~exist('runs', 'dir')
    mkdir('runs');
end

diary(fullfile('runs','export_bfm_L4_combined_incompleteness_diary.txt'));

disp('Exporting BFM L4 results: combined incompleteness');

global BELIEF VARIABLE ATTRIBUTE STRUCTURE FRAME QUERY BELTRACE
global NODE BJTREE TRANPROTOCOL;

% ------------------------------------------------------------
% Base L0 UIL
% ------------------------------------------------------------

l0_uil = fullfile('uilfiles','ten_cube_L0_complete_s8.txt');

if ~exist(l0_uil, 'file')
    error('Could not find L0 UIL file. Run run_10cube_L0_scenario8.m first.');
end

% Temporary scenario-specific files overwritten per scenario
temp_uil = fullfile('uilfiles','ten_cube_L4_temp_scenario.txt');
temp_bm_file = 'bm_ten_cube_L4_temp_scenario';

% Visual observation-rule reliability
rule_reliability = 0.80;
rule_ignorance = 1 - rule_reliability;

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

scenario_ids = [15, 16];

rows = {};

% ------------------------------------------------------------
% Run derived L4 scenarios
% ------------------------------------------------------------

for s_idx = 1:length(scenario_ids)

    scenario_id = scenario_ids(s_idx);

    fprintf('\n============================================================\n');
    fprintf('Scenario %d - L4 combined incompleteness\n', scenario_id);
    fprintf('============================================================\n');

    % --------------------------------------------------------
    % Build scenario-specific L4 UIL
    % --------------------------------------------------------

    txt = fileread(l0_uil);

    % Weaken visual observation rules for all L4 scenarios.
    txt = weaken_visual_observation_rules(txt, rule_reliability, rule_ignorance);

    switch scenario_id

        case 15
            % Battery/PSU ambiguity:
            % key MPS measurement is missing, and power-subsystem priors
            % are unknown.
            txt = replace_power_subsystem_priors_with_ignorance(txt);

        case 16
            % Module-3 boundary ambiguity:
            % key I3 observation is missing, and switch/cable family
            % priors are unknown.
            txt = replace_all_switch_priors_with_ignorance(txt);
            txt = replace_all_cable_priors_with_ignorance(txt);

        otherwise
            error(['Unknown L4 scenario_id: ', num2str(scenario_id)]);
    end

    fid = fopen(temp_uil, 'w');
    if fid == -1
        error('Could not open temporary L4 UIL for writing.');
    end
    fprintf(fid, '%s', txt);
    fclose(fid);

    disp(['Temporary L4 UIL written for scenario ', num2str(scenario_id)]);

    % --------------------------------------------------------
    % Convert and load scenario-specific BFM model
    % --------------------------------------------------------

    clearvars -global BELIEF VARIABLE ATTRIBUTE STRUCTURE FRAME QUERY BELTRACE NODE BJTREE TRANPROTOCOL
    global BELIEF VARIABLE ATTRIBUTE STRUCTURE FRAME QUERY BELTRACE
    global NODE BJTREE TRANPROTOCOL;

    disp('Converting temporary L4 UIL to BFM model...');
    uil2bm(temp_uil, temp_bm_file);

    if ~exist([temp_bm_file '.mat'], 'file')
        error(['uil2bm did not create ', temp_bm_file, '.mat. Check UIL syntax.']);
    end

    disp('Loading temporary L4 BFM model...');
    load(temp_bm_file);

    disp('Embedding conditional beliefs...');
    embelall = condiembed([BELIEF(:).number]);

    disp('Keeping embedded beliefs...');
    keepbel(embelall);

    disp(['Number of embedded beliefs: ', num2str(length(embelall))]);

    % --------------------------------------------------------
    % Scenario evidence
    % --------------------------------------------------------

    obs = make_scenario_observations_L4(scenario_id);

    disp('Evidence used:');
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
            'L4_combined_incompleteness', ...
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

out_path = fullfile('runs','bfm_L4_combined_incompleteness_results.csv');
writetable(T, out_path);

disp(['Saved BFM L4 results to: ', out_path]);

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

save(fullfile('runs','export_bfm_L4_combined_incompleteness_workspace.mat'));

diary off;

% ============================================================
% Helper functions: scenario evidence
% ============================================================

function obs = make_scenario_observations_L4(scenario_id)

    obs = [];

    switch scenario_id

        case 15
            % Battery discharge observed, PSU-short measurement missing.
            %
            % Evidence:
            %   OPSU = off
            %   I1-I8 = off
            %   OLa = off
            %   OLi = off
            %   MB = v0
            %   MPS = missing

            obs(end+1) = observe('OPSU', 'off');

            for n = 1:8
                obs(end+1) = observe(sprintf('I%d', n), 'off');
            end

            obs(end+1) = observe('OLa', 'off');
            obs(end+1) = observe('OLi', 'off');
            obs(end+1) = observe('MB', 'v0');

            % MPS intentionally not observed.

        case 16
            % Module-3 transition pattern with I3 missing.
            %
            % Evidence:
            %   OPSU = on
            %   I1 = on
            %   I2 = on
            %   I3 = missing
            %   I4-I8 = off
            %   OLa = off
            %   OLi = off
            %   MB = v12
            %   MPS = high

            obs(end+1) = observe('OPSU', 'on');
            obs(end+1) = observe('I1', 'on');
            obs(end+1) = observe('I2', 'on');

            % I3 intentionally not observed.

            for n = 4:8
                obs(end+1) = observe(sprintf('I%d', n), 'off');
            end

            obs(end+1) = observe('OLa', 'off');
            obs(end+1) = observe('OLi', 'off');
            obs(end+1) = observe('MB', 'v12');
            obs(end+1) = observe('MPS', 'high');

        otherwise
            error(['Unknown L4 scenario_id: ', num2str(scenario_id)]);
    end
end

% ============================================================
% Helper functions: prior replacement
% ============================================================

function txt = replace_power_subsystem_priors_with_ignorance(txt)

    txt = replace_psf_prior_with_ignorance(txt);
    txt = replace_battery_conditional_with_ignorance(txt);
end


function txt = replace_psf_prior_with_ignorance(txt)

    txt = strrep(txt, ...
        'SET VALUATION PR_PSF {yes} 0.005, {no} 0.995;', ...
        'SET VALUATION PR_PSF {no yes} 1;');
end


function txt = replace_battery_conditional_with_ignorance(txt)

    txt = strrep(txt, ...
        'SET CONDITIONAL VALUATION PB0 GIVEN {no}, {exh} 0.080, {good} 0.920;', ...
        'SET CONDITIONAL VALUATION PB0 GIVEN {no}, {good exh} 1;');

    txt = strrep(txt, ...
        'SET CONDITIONAL VALUATION PB1 GIVEN {yes}, {exh} 0.950, {good} 0.050;', ...
        'SET CONDITIONAL VALUATION PB1 GIVEN {yes}, {good exh} 1;');
end


function txt = replace_all_switch_priors_with_ignorance(txt)

    for idx = 1:8
        txt = replace_switch_prior_with_ignorance(txt, idx);
    end
end


function txt = replace_all_cable_priors_with_ignorance(txt)

    for idx = 1:8
        txt = replace_cable_prior_with_ignorance(txt, idx);
    end

    % Cable-to-load prior belongs to the cable family.
    txt = strrep(txt, ...
        'SET VALUATION PR_CL {bro} 0.020, {ok} 0.980;', ...
        'SET VALUATION PR_CL {ok bro} 1;');
end


function txt = replace_switch_prior_with_ignorance(txt, idx)

    old_line = sprintf('SET VALUATION PR_SW%d {det} 0.030, {ok} 0.970;', idx);
    new_line = sprintf('SET VALUATION PR_SW%d {ok det} 1;', idx);

    txt = strrep(txt, old_line, new_line);
end


function txt = replace_cable_prior_with_ignorance(txt, idx)

    old_line = sprintf('SET VALUATION PR_C%d {bro} 0.020, {ok} 0.980;', idx);
    new_line = sprintf('SET VALUATION PR_C%d {ok bro} 1;', idx);

    txt = strrep(txt, old_line, new_line);
end

% ============================================================
% Helper functions: weaken visual observation rules
% ============================================================

function txt = weaken_visual_observation_rules(txt, rule_reliability, rule_ignorance)

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
end

% ============================================================
% Helper function: extract belief/plausibility
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