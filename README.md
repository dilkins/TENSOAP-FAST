# SOAPFAST with FORTRAN

This code allows the use of models trained using the SOAPFAST code; the key parts of this code are re-implemented in FORTRAN, making them faster and more parallelizable.

# Requirements and Installation

I have tested this code with `gfortran`, version `7.4.0`. In order to compile this code, it should suffice to run the `configuration` script in the topmost directory. This will search for the required libraries, and compile them from scratch if needed; it will then produce a `Makefile`, so that you can compile the code by running `make` in the `src` directory.

It should be noted that there is no guarantee this code is as optimized as it can be; further, if you already have the required libraries (`BLAS`, `lapack`, `fftw3`) on your system these are recommended, rather than compiling your own version.

# Use

In order to use this code, the first thing needed is a model produced using SOAPFAST. There are a couple of requirements:

1. Power spectra should be sparsified on spherical harmonic components. This means that there will be two files, with names like `PS_fps.npy` and `PS_Amat.npy` providing sparsification details.
2. Power spectra should also be sparsified over environments. There will be a single sparsified power spectra, with a name like `PS.npy`
3. Finally, there should be a weights file, with a name like `weights_0.npy`.

To create model files, run `/path/to/soapfast_fortran/bin/sagpr_convert_model -ps PS.npy -sf PS -w weights_0.npy -hp "HYPERPARAMETERS" -o fname`, where the `PS` in `-sf PS` is the prefix to `_fps.npy` and `_Amat.npy`. The hyperparameters should consist of all other arguments to be passed to the power spectrum and kernel calculations, e.g. `-p -n 5 -l 3 -z 2` for a periodic calculation with `nmax=5`, `lmax=3` and `zeta=2`.

This will create two files, `fname.mdl` (a binary file containing the training power spectrum, sparsification details and weights) and `fname.hyp` (containing the hyperparameters in text format).

There are two modes of use:

1. `sagpr_apply`, which is used as `/path/to/soapfast_fortran/bin/sagpr_apply -f file_name.xyz -m fname -o prediction.out`, which uses the model specified by `fname.{mdl,hyp}` to make predictions about `file_name.xyz`, storing them in `prediction.out`. *Note: these models can only be for a single spherical component; a separate prediction must be done for each component.*
2. `sagpr_multi_apply` (recommended), which is used as `/path/to/soapfast_fortran/bin/sagpr_multi_apply -m fname -o prediction.out`, which creates a named pipe, `my_fifo_in`, into which multiple coordinate files can be piped using, e.g. `cat file_name.xyz > my_fifo_in`. The predictions are computed and stored in `prediction.out`. They can also be obtained using the pipe `my_fifo_out`. This is the recommended option because all arrays are set up, models are loaded, and can be applied an indefinite number of times without having to re-initialize anything.

# Maintenance

Please contact david.wilkins@epfl.ch with any problems.