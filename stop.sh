#!/bin/sh

# Stop a baking setup.
# Chris Pinnock 2022
# MIT license
#

pkill octez-node
pkill octez-dal-node
pkill octez-baker

