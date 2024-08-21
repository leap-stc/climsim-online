# Evaluating Online Performance using hybrid-ML simulation on Google Compute Engine Virtual Machine

## Required IAM Roles

The user account you use here should have 'Compute Admin' and 'Service Acccount User' roles

## Create the VM instance

Navigate to "Compute Engine > VM instances"

Click "Create Instance" and change the following settings from the default:

- Machine configuration: Choose a machine type with at least 8 cores and 32GB RAM (tested on 'e2-standard-16')
- Container: Click "Deploy Container" and paste `quay.io/akshaysubr/climsim-testing:e3sm-mmf-nn-2024-06-24` into the "Container Image" field. 
    >[!IMPORTANT]
    > For this container version it is also necessary to specify `/bin/bash` in the "Command" field and setting both "Allocate a buffer for STDIN" and "Allocate a pseudo-TTY" to True.

- Boot Disk: Increase the size of the boot disk to 100GB to accomodate the docker image and the input file downloads. NOTE: This must be done after setting the “Deploy Container” option or it will get reset to 10GB and that will cause the container pull to fail
- Click "Create"
- After the instance is created, SSH into the VM instance, and run `docker ps` to verify that the E3SM container is running. If you see only a `gcr.io/gce-containers/konlet` image running, wait for a bit since that container is used to set up the E3SM container. The container is fairly large and pulling it might take some time. You can monitor network traffic by clicking on the triple dot next to your VM in the "VM instance" panel and choose "View monitoring". Once the container is pulled you should see Network Traffic drop.
    - In our test case the download took about 3 minutes.
- Check `ps docker` again and confirm that the status for `quay.io/akshaysubr/climsim-testing:e3sm-mmf-nn-2024-06-241` is 'Up XXX seconds/minutes'.

> If you still do not see the container running, check for errors with `sudo journalctl -u konlet-startup`

- Once the climsim container is running, you can get shell access in the climsim container using `docker exec -it <CONTAINER ID> /bin/bash`
- Update the E3SM repository. There are updates on E3SM codes that are not yet included in the container.
    - `cd /climsim`
    - `mv E3SM E3SM_old`
    - `git clone https://github.com/NVlabs/E3SM.git`
    - `cd E3SM`
    - `git config --global url.https://github.com/.insteadOf git@github.com:`
    - `git submodule update --init --recursive`

- Download the E3SM restart files:
    -  running `pip install gdown && gdown --fuzzy https://drive.google.com/file/d/1rH8GIx6r5rurUpzaibH3gbDksv-gViXk/view?usp=share_link`
    -  Extract the downloade file under `/storage`, e.g., `tar -xzvf shared_e3sm.tar.gz -C /storage/`

- Now follow the instructions in the [README](./README.md) (shortened here, only essential steps)

    - `mkdir inputdata scratch`
    - `cd /climsim/E3SM/climsim_scripts`
    - `python example_job_submit_nnwrapper_v4_constrained.py`
