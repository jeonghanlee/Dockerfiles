#!/usr/bin/env bash

tr -cd 0-9 </dev/urandom | head -c 8 > .trigger/random
