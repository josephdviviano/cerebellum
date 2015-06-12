#!/bin/bash

tail -n +6 atlas_civ.R.1D | tr -s ' '  | cut -d ' ' -f 8  > right_mask.1D
