# ClimSim Online

## Getting started

To evaluate online performance using Google Compute Engine Virtual Machine, [follow these instructions](./cloud_vm.md).

The workflow can also be run on a local linux x86_64 system as well. Instructions for using local resources are in [Local setup](#local-setup)

## Local setup

Clone the repo first
```
git clone ssh://git@gitlab-master.nvidia.com:12051/earth-2/climsim-online.git
```

Then update all the submodules
```
cd climsim-online
git submodule update --init --recursive
```

## Building the container

Just run `./docker_build.sh`

## Running a control MMF simulation workflow

1. Ensure the right directories are created:

    a. `mkdir inputdata` to create the directory used for E3SM input data. This data will be auto-downloaded during the first E3SM run.

    b. `mkdir scratch` to use as the directory that hosts the binaries and all the output data from the run.

2. Launch the container using `./docker_launch.sh`

3. Navigate to the `climsim_scripts` directory: `cd /climsim/E3SM/climsim_scripts`

4. Launch the control MMF simulation job using `python example_job_submit_mmf.py`

## Running an online hybrid simulation workflow

1. Ensure the right directories are created:

    a. `mkdir inputdata` to create the directory used for E3SM input data. This data will be auto-downloaded during the first E3SM run.

    b. `mkdir scratch` to use as the directory that hosts the binaries and all the output data from the run.

    c. Extract the tarball downloaded from [here](https://drive.google.com/file/d/1rH8GIx6r5rurUpzaibH3gbDksv-gViXk/view?usp=share_link): `tar xvfz shared_e3sm.tar.gz`. 
    This will create a `shared_e3sm` that hosts all the NN models, normalization params, restart files, and reference e3sm simulation outputs needed.

2. Launch the container using `./docker_build.sh`

3. Navigate to the `climsim_scripts` directory: `cd /climsim/E3SM/climsim_scripts`

4. Launch the control MMF simulation job using `python example_job_submit_nnwrapper_v4_constrained.py`

## Evaluation
--------------------------------------------------------------------------------
After you the hybrid simulation, to make the evaluation plot, you can go to the `cd /climsim/E3SM/climsim_scripts` directory and execute the following file:
```
python example_plot_monthly_rmse.py /storage/shared_e3sm/ /scratch/example_job_submit_nnwrapper_v4_constrained/run/
```
Change the first path to the `shared_e3sm` folder, and change the second path to the folder that contains the model output. This python script will generete a figure of monthly RMSE of temperature and moisture under `climsim_scripts/figure`.

To get access to this plot, you can copy it to the mounted scratch volume using
```
cp -r figure /scratch/example_job_submit_nnwrapper_v4_constrained/
```

## License

climsim-online is provided under the Apache License 2.0, please see [LICENSE.txt](./LICENSE.txt)
for full license text.
