dir=JHUGentest_`date +%Y%m%d_%H%M%S`
mkdir -p $dir

echo "cd $(pwd)
./superJHUGentest.sh $dir
" | bsub -q 1nw -o $dir/STDOUT -e $dir/STDERR -J $dir
