dir=JHUGentest_`date +%Y%m%d_%H%M%S`
mkdir $dir

cd JHUGen/JHUGenerator
git fetch
make clean
git checkout -- .

#http://stackoverflow.com/questions/3258243/git-check-if-pull-needed
LOCAL=$(git rev-parse @)
REMOTE=$(git rev-parse @{u})
BASE=$(git merge-base @ @{u})
if [ $LOCAL = $REMOTE ]; then
    echo "JHUGen is up to date"
elif [ $LOCAL = $BASE ]; then
    echo "Need to pull JHUGen..."
    git pull -X theirs
else
    echo "Looks like there are local JHUGen commits!  Exiting."
    exit 1
fi

echo "Recompiling JHUGen..."
if ! make; then
    echo "Couldn't compile JHUGen!  Exiting."
    exit 1
fi

echo "Generating gg --> H --> ZZ..."
./JHUGen Collider=1 Process=0 VegasNc2=25 OffXVV=011 DecayMode1=9 DecayMode2=9 Unweighted=.true. DataFile=../../$dir/spin0_HZZ
echo "Generating qqb --> spin1 --> WW..."
./JHUGen Collider=1 Process=1 VegasNc2=25 OffXVV=011 DecayMode1=11 DecayMode2=11 Unweighted=.true. DataFile=../../$dir/spin1_HWW
echo "Generating gg/qqb --> spin2 --> ZZ..."
./JHUGen Collider=1 Process=2 VegasNc2=25 PChannel=2 OffXVV=011 DecayMode1=9 DecayMode2=9 Unweighted=.true. DataFile=../../$dir/spin2_HZZ
echo "Generating WH..."
./JHUGen Collider=1 Process=50 VegasNc2=25 OffXVV=011 DecayMode1=11 Unweighted=.true. DataFile=../../$dir/WH
echo "Decaying WH --> WW..."
./JHUGen ReadLHE=../../$dir/WH.lhe DataFile=../../$dir/WH_HWW DecayMode1=11 DecayMode2=11
echo "Generating ZH..."
./JHUGen Collider=1 Process=50 VegasNc2=25 OffXVV=011 DecayMode1=9 Unweighted=.true. DataFile=../../$dir/ZH
echo "Decaying ZH --> ZZ..."
./JHUGen ReadLHE=../../$dir/ZH.lhe DataFile=../../$dir/ZH_HZZ DecayMode1=9 DecayMode2=9
echo "Generating VBF..."
./JHUGen Collider=1 Process=60 VegasNc2=25 OffXVV=011 Unweighted=.true. DataFile=../../$dir/VBF
echo "Decaying VBF --> WW..."
./JHUGen ReadLHE=../../$dir/VBF.lhe DataFile=../../$dir/VBF_HWW DecayMode1=11 DecayMode2=11
echo "Generating HJJ..."
./JHUGen Collider=1 Process=61 VegasNc2=25 OffXVV=011 Unweighted=.true. DataFile=../../$dir/HJJ
echo "Decaying HJJ --> ZZ..."
./JHUGen ReadLHE=../../$dir/HJJ.lhe DataFile=../../$dir/HJJ_HZZ DecayMode1=9 DecayMode2=9
echo "Generating HJ..."
./JHUGen Collider=1 Process=62 VegasNc2=25 OffXVV=011 Unweighted=.true. DataFile=../../$dir/HJ
echo "Decaying HJ --> WW..."
./JHUGen ReadLHE=../../$dir/HJ.lhe DataFile=../../$dir/HJ_HWW DecayMode1=11 DecayMode2=11
echo "Generating ttH..."
./JHUGen Collider=1 Process=80 VegasNc2=25 OffXVV=011 Unweighted=.true. DataFile=../../$dir/ttH
echo "Decaying ttH --> ZZ..."
./JHUGen ReadLHE=../../$dir/ttH.lhe DataFile=../../$dir/ttH_HZZ DecayMode1=9 DecayMode2=9
echo "Generating bbH..."
./JHUGen Collider=1 Process=90 VegasNc2=25 OffXVV=011 Unweighted=.true. DataFile=../../$dir/bbH
echo "Decaying bbH --> WW..."
./JHUGen ReadLHE=../../$dir/bbH.lhe DataFile=../../$dir/bbH_HWW DecayMode1=11 DecayMode2=11

cd ../../checklhe/
echo "Pulling checklhe script..."
git pull
cd ../$dir
echo "Running checklhe..."
python ../checklhe/checklhe.py *.lhe
