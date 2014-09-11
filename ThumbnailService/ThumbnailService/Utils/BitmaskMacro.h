//
// Created by Aleksey Garbarev on 11.09.14.
// Copyright (c) 2014 Aleksey Garbarev. All rights reserved.
//

#define SET_BITMASK(source, mask, enabled) if (enabled) { source |= mask; } else { source &= ~mask; }
#define GET_BITMASK(source, mask) (source & mask)
