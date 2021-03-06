#!/usr/bin/env julia

using ArgParse
using DataDeps
using PyCall

const shutil = pyimport("shutil")


function parse_commandline()
    settings = ArgParseSettings(description="""
    This script set up the needed databases for PhyloSofS in the `--output`
    path. If the `--pdb`, `--uniclust` or `--pdb70` argument is used, the
    script is going to create a symbolic link to the indicated folder
    instead of downloading the database.

    It creates a `databases` folder in `--output` containing three folders:
    `pdb`, `uniclust` and `pdb70`
    """,)

    @add_arg_table settings begin
        "--output", "-o"
            help = "path where the database folder is going to be created."
            default = "."
        "--pdb"
            help = """
            path to an already existing local folder containing the entire pdb
            in mmCIF format.
            """
            default = ""
        "--uniclust"
            help = """
            path to an already existing local folder containing the uniclust
            database from the HH-suite databases.
            """
            default = ""
        "--uniclust_version"
            help = """
            Uniclust30 version to be downloaded: YYYY_MM
            """
            default = "2018_08"
        "--pdb70"
            help = """
            path to an already existing local folder containing the
            pdb70_from_mmcif database from the HH-suite databases.
            """
            default = ""
    end

    return parse_args(settings)
end


"Free space in Gb at the given path."
free_space(path) = shutil.disk_usage(path)[3] / 1000_000_000


function check_space(free, min_space, database_name)
    if free < min_space
        throw(ErrorException("""
        Free space: $free Gb
        Please make sure to have at least $min_space Gb of free disk space
        before downloading the $database_name database.
        """))
    end
end


"Try to decompress locally a basename.tr.gz file and delete the compressed files"
function _unpack_tar_gz(basename)
    try
        unpack("$basename.tar.gz")
    catch err
        @error err
    finally
        isfile("$basename.tar.gz") && rm("$basename.tar.gz")
        isfile("$basename.tar") && rm("$basename.tar")
    end
end


function main()
    execution_folder = pwd()
    parsed_args = parse_commandline()

    output_path = joinpath(abspath(parsed_args["output"]), "databases")
    mkpath(output_path)

    pdb = parsed_args["pdb"]
    uniclust = parsed_args["uniclust"]
    pdb70 = parsed_args["pdb70"]

    uniclust_version = parsed_args["uniclust_version"]

    pdb_path = joinpath(output_path, "pdb")
    uniclust_path = joinpath(output_path, "uniclust")
    pdb70_path = joinpath(output_path, "pdb70")

    free = free_space(output_path)

    @info """
    Setting up PDB database cache:
    In each PhyloSofS run, the needed PDB files in mmCIF format are going to be
    downloaded into $pdb_path if they aren't already there.
    """

    if pdb == ""
        mkpath(pdb_path)
    else
        pdb = abspath(pdb)
        symlink(pdb, pdb_path)
    end

    @info "Setting up pdb70 (HH-suite database)"

    if pdb70 == ""
        check_space(free, 42, "HH-suite pdb70_from_mmcif")
        mkpath(pdb70_path)
        cd(pdb70_path)
        retry(download, delays=ExponentialBackOff(n=2))(
            "http://wwwuser.gwdg.de/~compbiol/data/hhsuite/databases/hhsuite_dbs/pdb70_from_mmcif_latest.tar.gz",
            "pdb70.tar.gz")
        _unpack_tar_gz("pdb70")
        cd(execution_folder)
    else
        pdb70 = abspath(pdb70)
        mkpath(pdb70_path)
        for file in readdir(pdb70)
            if filesize(file) > 0
                symlink(joinpath(pdb70, file), joinpath(pdb70_path, file))
            end
        end
    end

    @info "Setting up Uniclust30 (HH-suite database)"

    if uniclust == ""
        check_space(free, 87, "HH-suite Uniclust30")
        cd(output_path)
        retry(download, delays=ExponentialBackOff(n=2))(string(
            "http://wwwuser.gwdg.de/~compbiol/uniclust/", uniclust_version,
            "/uniclust30_", uniclust_version, "_hhsuite.tar.gz"
            ), "uniclust.tar.gz")
        _unpack_tar_gz("uniclust";)
        for dir in ["uniclust30_$(uniclust_version)",
                    "uniclust30_$(uniclust_version)_hhsuite"]
            if isdir(dir)
                mv(dir, "uniclust")
            end
        end
        cd(execution_folder)
    else
        uniclust = abspath(uniclust)
        mkpath(uniclust_path)
        for file in readdir(uniclust)
            if filesize(file) > 0
                symlink(joinpath(uniclust, file), joinpath(uniclust_path, file))
            end
        end
    end

    cd(uniclust_path)
    to_erase = string("30_", uniclust_version)
    for file in readdir()
        if occursin(to_erase, file)
            if filesize(file) > 0
                symlink(file, replace(file, to_erase => ""))
            end
        end
    end
    cd(execution_folder)

end

main()
