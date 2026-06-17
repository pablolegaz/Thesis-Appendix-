# Experiment design

The experiments evaluate whether belief-network inference remains diagnostically useful when probabilistic information is progressively removed.

## L0 complete model

The complete BFM model is used as a validation point. Under complete probabilistic information, belief and plausibility collapse to point values, and the BFM output can be compared with the complete Bayesian-network reference model.

## L1 local prior ignorance

Only locally relevant priors are replaced by vacuous ignorance. This represents a situation where the system structure is known, but the reliability information for a specific component is not trusted or unavailable.

## L2 fault-family prior ignorance

A broader family of priors is replaced by ignorance. For example, all switch/cable priors may be removed for control-chain scenarios. This tests whether the model preserves physical diagnostic localisation when a whole subsystem has missing reliability information.

## L3 / L3b observation uncertainty

Intermediate work. L3 discounts the scenario evidence itself. L3b weakens visual observation rules in the model. These scripts support the final combined L4 setup.

## L4 combined incompleteness

Missing observations, missing priors, and weakened visual observation rules are combined. This is the strongest stress test and is used to identify the boundary between useful localisation and too-broad diagnostic output.
