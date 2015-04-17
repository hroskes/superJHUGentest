if ! [ -d $1 ]; then
    echo "superJHUGentest.sh needs an existing directory as an argument!"
    exit 1
fi

dir=$1

cd JHUGen/JHUGenerator
echo "Getting the latest JHUGen version..."
git fetch
make clean
git checkout -- .
git pull
#modifications to decay JHUGen samples
sed -i "s/InputLHEFormat = 1/InputLHEFormat = 3/" main.F90
make

echo "===================="
echo "=====Generation====="
echo "===================="

echo "Generating gg --> H --> ZZ..."
./JHUGen Collider=1 Process=0 VegasNc2=25 OffXVV=011 DecayMode1=9 DecayMode2=9 Unweighted=1 DataFile=../../$dir/spin0_HZZ
echo "Generating qqb --> spin1 --> WW..."
./JHUGen Collider=1 Process=1 VegasNc2=25 OffXVV=011 DecayMode1=11 DecayMode2=11 Unweighted=1 DataFile=../../$dir/spin1_HWW
echo "Generating gg/qqb --> spin2 --> ZZ..."
./JHUGen Collider=1 Process=2 VegasNc2=25 PChannel=2 OffXVV=011 DecayMode1=9 DecayMode2=9 Unweighted=1 DataFile=../../$dir/spin2_HZZ
echo "Generating WH..."
./JHUGen Collider=1 Process=50 VegasNc2=25 OffXVV=011 DecayMode1=11 Unweighted=1 DataFile=../../$dir/WH
echo "Decaying WH --> WW..."
./JHUGen ReadLHE=../../$dir/WH.lhe DataFile=../../$dir/WH_HWW DecayMode1=11 DecayMode2=11
echo "Generating ZH..."
./JHUGen Collider=1 Process=50 VegasNc2=25 OffXVV=011 DecayMode1=9 Unweighted=1 DataFile=../../$dir/ZH
echo "Decaying ZH --> ZZ..."
./JHUGen ReadLHE=../../$dir/ZH.lhe DataFile=../../$dir/ZH_HZZ DecayMode1=9 DecayMode2=9
echo "Generating VBF..."
./JHUGen Collider=1 Process=60 VegasNc2=25 OffXVV=011 Unweighted=1 DataFile=../../$dir/VBF
echo "Decaying VBF --> WW..."
./JHUGen ReadLHE=../../$dir/VBF.lhe DataFile=../../$dir/VBF_HWW DecayMode1=11 DecayMode2=11
echo "Generating HJJ..."
./JHUGen Collider=1 Process=61 VegasNc2=25 OffXVV=011 Unweighted=1 DataFile=../../$dir/HJJ
echo "Decaying HJJ --> ZZ..."
./JHUGen ReadLHE=../../$dir/HJJ.lhe DataFile=../../$dir/HJJ_HZZ DecayMode1=9 DecayMode2=9
echo "Generating HJ..."
./JHUGen Collider=1 Process=62 VegasNc2=25 OffXVV=011 Unweighted=1 DataFile=../../$dir/HJ
echo "Decaying HJ --> WW..."
./JHUGen ReadLHE=../../$dir/HJ.lhe DataFile=../../$dir/HJ_HWW DecayMode1=11 DecayMode2=11
echo "Generating ttH..."
./JHUGen Collider=1 Process=80 VegasNc2=25 OffXVV=011 Unweighted=1 DataFile=../../$dir/ttH
echo "Decaying ttH --> ZZ..."
./JHUGen ReadLHE=../../$dir/ttH.lhe DataFile=../../$dir/ttH_HZZ DecayMode1=9 DecayMode2=9
echo "Generating bbH..."
./JHUGen Collider=1 Process=90 VegasNc2=25 OffXVV=011 Unweighted=1 DataFile=../../$dir/bbH
echo "Decaying bbH --> WW..."
./JHUGen ReadLHE=../../$dir/bbH.lhe DataFile=../../$dir/bbH_HWW DecayMode1=11 DecayMode2=11

echo "=================="
echo "=====checklhe====="
echo "=================="

cd ../../checklhe/
echo "Pulling checklhe script..."
git pull
cd ../$dir
echo "Setting up CMSSW area (needed for python version)..."
export SCRAM_ARCH=slc6_amd64_gcc481
scram p CMSSW CMSSW_7_1_14
cd CMSSW_7_1_14/src
eval $(scram ru -sh)
cd ../..
echo "Running checklhe..."
python ../checklhe/checklhe.py *.lhe

echo "================"
echo "=====pythia====="
echo "================"

echo "Setting up pythia..."

cd CMSSW_7_1_14/src
mkdir -p Configuration/GenProduction/python/ThirteenTeV/
cp ../../../forpythia/Hadronizer_TuneCUETP8M1_13TeV_generic_LHE_pythia8_Tauola_cff.py Configuration/GenProduction/python/ThirteenTeV/
scram b
ln -s ../../*.lhe .

for a in *.lhe; do
    echo "Hadronizing $a..."
    lhefile=$a &&
    GENfile=${a/.lhe/-GEN.root} &&
    GENcfg=${a/.lhe/-GEN_cfg.py} &&
    GENSIMfile=${a/.lhe/-GEN-SIM_py8.root} &&
    GENSIMcfg=${a/.lhe/-GEN-SIM_py8_cfg.py} &&
    GENSIMcfgtemplate=${GENSIMcfg/_cfg.py/_cfg_template.py} &&
    cmsDriver.py step1 --filein file:$lhefile --fileout file:$GENfile --mc --eventcontent LHE --datatier GEN --conditions MCRUN2_71_V1::All --step NONE --python_filename $GENcfg --no_exec --customise Configuration/DataProcessing/Utils.addMonitoring -n -1 &&
    cmsRun $GENcfg &&
    cmsDriver.py Configuration/GenProduction/python/ThirteenTeV/Hadronizer_TuneCUETP8M1_13TeV_generic_LHE_pythia8_Tauola_cff.py --filein file:$GENfile --fileout file:$GENSIMfile --mc --eventcontent RAWSIM --customise SLHCUpgradeSimulations/Configuration/postLS1Customs.customisePostLS1,Configuration/DataProcessing/Utils.addMonitoring --datatier GEN-SIM --conditions MCRUN2_71_V1::All --step GEN,SIM --magField 38T_PostLS1 --python_filename $GENSIMcfg --no_exec -n 10000 &&
    cmsRun $GENSIMcfg
done
