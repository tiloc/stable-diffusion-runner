#!/bin/bash

set -e

mydir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Include pashua.sh to be able to use the 2 functions defined in that file
# shellcheck source=/dev/null
source "$mydir/pashua.sh"

# Define what the dialog should be like
# Take a look at Pashua's Readme file for more info on the syntax

conf="
# Set window title
*.title = Welcome to Stable Diffusion Runner

# Prompt
tf.type = textbox
tf.label = Describe your idea
tf.width = 310
tf.height = 200
tf.mandatory = true
tf.tooltip = Write an idea, such as the description of a scene

# Add a samplingup menu
sampling.type = popup
sampling.label = Sampling steps
sampling.width = 310
sampling.option = 1
sampling.option = 10
sampling.option = 30
sampling.option = 50
sampling.default = 30
sampling.tooltip = How many sampling steps for PLMS?

# Add a cancel button with default label
cb.type = cancelbutton
cb.tooltip = Cancel and do not run

db.type = defaultbutton
db.label = Run
db.tooltip = Click to run
"

if [ -d '/Volumes/Pashua/Pashua.app' ]
then
	# Looks like the Pashua disk image is mounted. Run from there.
	customLocation='/Volumes/Pashua'
else
	# Search for Pashua in the standard locations
	customLocation=''
fi

locate_pashua "$customLocation"
pashua_run "$conf" "$customLocation"

echo "${tf:?}" > /dev/null
echo "${sampling:?}" > /dev/null
echo "${cb:?}" > /dev/null

if [[ "$cb" == "1" ]]
then
echo "Cancelled - Exit"
exit 130
fi

outdir=$(pwd)/../stable-diffusion-output
mkdir -p "$outdir"

pushd ../stable-diffusion || exit
# shellcheck source=/dev/null
source venv/bin/activate
python scripts/txt2img.py --prompt "$tf" --n_samples 1 --n_iter 1 --plms --ddim_steps "$sampling" --outdir "$outdir"
popd || exit

unset -v latest
for file in "$outdir"/*; do
  [[ $file -nt $latest ]] && latest=$file
done

echo "Image saved to $latest"
open "$latest"
