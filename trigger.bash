#!/usr/bin/env bash

LC_ALL=C tr -cd 0-9 </dev/urandom | head -c 8 > .trigger/random
