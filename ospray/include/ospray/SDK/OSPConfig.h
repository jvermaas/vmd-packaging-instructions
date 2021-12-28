// Copyright 2009-2019 Intel Corporation
// SPDX-License-Identifier: Apache-2.0

#pragma once

#define TILE_SIZE 64
#define MAX_TILE_SIZE 128

/*! number of pixels that each job in a parallel rendertile task
    executes together. Must be a multipel of the maximum possible
    programCount (16), and must be smaller than TILE_SIZE (in one
    dimension) */
#define RENDERTILE_PIXELS_PER_JOB 64
