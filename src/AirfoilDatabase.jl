"""
# DESCRIPTION
    Database for managing airfoil polar information.

# AUTHORSHIP
  * Author    : Eduardo J. Alvarez
  * Email     : Edo.AlvarezR@gmail.com
  * Created   : Jun 2020
  * License   : MIT
"""
module AirfoilDatabase

# ------------ GENERIC MODULES -------------------------------------------------
import DataStructures: OrderedDict
import DataFrames
import JuliaDB

const jdb = JuliaDB

# ------------ FLOW CODES ------------------------------------------------------
# https://github.com/byuflowlab/AirfoilPrep.jl
import AirfoilPrep
const ap = AirfoilPrep

# ------------ GLOBAL VARIABLES ------------------------------------------------
const module_path = splitdir(@__FILE__)[1]                   # Path to this module
const def_database = joinpath(module_path, "../database/")   # Path to default database

const DIR_XY = "xy"         # xy directory
const DIR_CL = "Cl"         # Cl directory
const DIR_CD = "Cd"         # Cd directory
const DIR_CM = "Cm"         # Cm directory
const DIR_XUP = "xupsep"    # xupsep directory
const DIR_XLO = "xlosep"    # xlosep directory
const DEF_NDXFL = "index.csv" # Default indexing file name
const RQRD = "required"     # Default value for requiered fields
const PTNL_S = " "          # Default value for optional String fields
const PTNL_R = 0            # Default value for optional Real fields
const PTNL_I = 0            # Default value for optional Int fields
const PTNL_B = true         # Default value for optional Boolean fields
                            # Labels of each database entry
const LBLS = OrderedDict(#  hash_key        => (csv_header, default_value, type, description)
                            :airfoilname    => ("Airfoil", RQRD, String, "Airfoil name"),
                            :re             => ("Re", PTNL_R, Real, "Reynolds number"),
                            :ma             => ("Mach", PTNL_R, Real, "Mach number"),
                            :npanels        => ("Panels", PTNL_I, Int, "Number of panels (XFOIL)"),
                            :ncrit          => ("Ncrit", PTNL_R, Real, "XFOIL Ncrit parameter"),
                            :deg            => ("Degrees", PTNL_B, Bool, "XFOIL Ncrit parameter"),
                            :xyfile         => ("xy file", RQRD, String, "Airfoil contour file"),
                            :clfile         => ("Cl file", PTNL_S, String, "Cl file"),
                            :cdfile         => ("Cd file", PTNL_S, String, "Cd file"),
                            :cmfile         => ("Cm file", PTNL_S, String, "Cm file"),
                            :xupsepfile     => ("xupsep file", PTNL_S, String, "xupsep file"),
                            :xlosepfile     => ("xlosep file", PTNL_S, String, "xlosep file"),
                            :diff           => ("Differentiator", PTNL_I, Int, "Differentiator number (for accepting duplicates)"),
                        )

const RQRD_FIELDS = [key for (key, val) in LBLS  if val[2]==RQRD]   # Required fields
const ID_FIELDS = [:airfoilname, :re, :ma, :npanels, :ncrit, :deg, :diff] # Fields that make an entry unique

const HEADER2FIELD = Dict((val[1], key) for (key, val) in LBLS)     # Hash CSV header to field
const FIELD2HEADER = Dict((key, val[1]) for (key, val) in LBLS)     # Hash field to CSV header
const HEADER_2FIELD = Dict((replace(val[1], " "=>"_"), key) for (key, val) in LBLS)  # Hash CSV header (with spaces as _) to field
const FIELD2_HEADER = Dict((key, replace(val[1], " "=>"_")) for (key, val) in LBLS)  # Hash field to CSV header (with spaces as _)

const DIRS = Dict(  :xyfile=>DIR_XY,                                # Hash field to directory
                    :clfile=>DIR_CL, :cdfile=>DIR_CD, :cmfile=>DIR_CM,
                    :xupsepfile=>DIR_XUP, :xlosepfile=>DIR_XLO)

function _lbls2dataframe()
    df = DataFrames.DataFrame(;(
                                (Symbol("Field"), collect(keys(LBLS))),
                                (Symbol("Header"), [val[1] for val in values(LBLS)]),
                                (Symbol("Default value"), [val[2] for val in values(LBLS)]),
                                (Symbol("Value type"), [val[3] for val in values(LBLS)]),
                                (Symbol("Description"), [val[4] for val in values(LBLS)]),
                             )...)
    return df
end

# ------------ HEADERS ---------------------------------------------------------
# Load headers
for header_name in []
    include("AirfoilDatabase_"*header_name*".jl")
end

# ------------------------------------------------------------------------------
"""
    `new_database(path::String; index_file::String=DEF_NDXFL, mkpath_optargs=[],
prompt=true, v_lvl=0)`

Creates a new airfoil database in the given path.
"""
function new_database(path::String;                          # Path of new database
                        # DATABASE OPTIONS
                        index_file::String=DEF_NDXFL,        # Name of indexing file
                        # OUTPUT OPTIONS
                        mkpath_optargs=[], prompt=true, v_lvl=0)

    # Case that path already exists
    if isdir(path)

        remove = true # Determine whether to remove it or not
        if prompt
            inp = ""
            while !(inp in ["y", "n"])
              print("\t"^v_lvl*"Directory $path already exists. Remove? (y/n) ")
              inp = readline()[1:end]
            end
            remove = inp=="y"
        end

        if remove; rm(path; recursive=true); end;
    end

    # Create path if it doesn't already exists
    mkpath(path; mkpath_optargs...)

    # Create subdirectories
    for dir in [DIR_XY, DIR_CL, DIR_CD, DIR_CM, DIR_XUP, DIR_XLO]
        mkpath(joinpath(path, dir); mkpath_optargs...)
    end

    # Create default indexing file
    f = open(joinpath(path, index_file), "w")

    for (coli, (key, val)) in enumerate(LBLS)
        print(f, val[1])
        print(f, coli==length(LBLS) ? "\n" : ",")
    end

    close(f)

    return joinpath(path, index_file)
end

"""
    `new_entry(; database_path::String=$(def_database), index_file::String=$(DEF_NDXFL), lbls...)`

Adds a new entry to the database under `database_path` with indexing file
`index_file`. `lbls` are the labels of the entry (or columns of database), as
shown above (Fields is the name of the label):

$(_lbls2dataframe())

For instance, here is a dummy example on how to add an airfoil with only the
required fields: `db.new_entry(; airfoilname="NACA 0012", xyfile="naca0012.csv)`
"""
function new_entry(; database_path::String=def_database,
                        index_file::String=DEF_NDXFL,
                        check_duplicates::Bool=true,
                        lbls...)

    # Check that all required fields where given
    for field in RQRD_FIELDS
        if findfirst(x->x==field, keys(lbls))==nothing
            error("Required field $field was not given!")
        end
    end

    # Test that all fields are the correct type
    for (field, val) in LBLS
        if findfirst(x->x==field, keys(lbls)) != nothing
            try
                lbls[findfirst(x->x==field, keys(lbls))] :: val[3]
            catch e
                error("Expected type $(val[3]) under field $(field);"*
                        " got $(lbls[findfirst(x->x==field, keys(lbls))])"*
                        " (type $(typeof(lbls[findfirst(x->x==field, keys(lbls))])))."*
                        " Error: $(e)")
            end
        end
    end

    # Add missing optional fields
    this_lbls = [ (key,
                    findfirst(x->x==key, keys(lbls))==nothing ? val[2] : lbls[findfirst(x->x==key, keys(lbls))])
                   for (key, val) in LBLS]

    # Create default indexing file
    f = open(joinpath(database_path, index_file), "a")

    for (coli, key) in enumerate(keys(LBLS))
        val = this_lbls[findfirst(x->x[1]==key, this_lbls)][2]
        print(f, val)
        print(f, coli==length(LBLS) ? "\n" : ",")
    end

    close(f)
end

"""
    `new_entry(polar::AirfoilPrep.Polar; database_path::String=$(def_database), index_file::String=$(DEF_NDXFL), lbls...)`

Adds a new entry to the database under `database_path` with indexing file
`index_file`. `lbls` are the labels of the entry (or columns of database), as
shown above (Fields is the name of the label).
"""
function new_entry(polar::ap.Polar; database_path::String=def_database,
                                    ext::String=".csv", lbls...)

    # Get airfoil name
    if findfirst(x->x==:airfoilname, keys(lbls))==nothing
        error("Required field $(:airfoilname) was not given!")
    end

    rflname = replace("$(lbls[findfirst(x->x==:airfoilname, keys(lbls))])", " "=>"")

    # Add fields from polar
    this_lbls = Any[(key, val) for (key, val) in lbls]

    for (field, fun) in [ (:re, ap.get_Re), (:ma, ap.get_Ma),
                          (:npanels, ap.get_npanels), (:ncrit, ap.get_ncrit),
                          (:diff, (args...)->PTNL_I)]

        if findfirst(x->x==field, keys(lbls))==nothing # Check if field wasn't prescribed by user
            push!(this_lbls, (field, fun(polar)))
        end

    end

    # Build file names
    re = "$(ceil(Int, this_lbls[findfirst(x->x[1]==:re, this_lbls)][2]))"
    ma = "$(replace("$(this_lbls[findfirst(x->x[1]==:ma, this_lbls)][2])", "."=>"p"))"
    npanels = "$(replace("$(this_lbls[findfirst(x->x[1]==:npanels, this_lbls)][2])", "."=>"p"))"
    ncrit = "$(replace("$(this_lbls[findfirst(x->x[1]==:ncrit, this_lbls)][2])", "."=>"p"))"
    diff = "$(replace("$(this_lbls[findfirst(x->x[1]==:diff, this_lbls)][2])", "."=>"p"))"

    xyfile = rflname*"-npanels"*npanels*"-"*diff*ext
    suff = "-re"*re*"-ma"*ma*"-ncrit"*ncrit*"-"*diff*ext
    clfile = rflname*"-Cl"*suff
    cdfile = rflname*"-Cd"*suff
    cmfile = rflname*"-Cm"*suff
    cmfile = rflname*"-Cm"*suff
    # xupsepfile = rflname*"-xupsep"*suff
    # xlosepfile = rflname*"-xlosep"*suff

    # Create files and add them to the entry
    for (field, fun, file, dir, headers) in [ (:xyfile, ap.get_geometry, xyfile, DIR_XY, ["x", "y"]),
                                              (:clfile, ap.get_cl, clfile, DIR_CL, ["alpha", "cl"]),
                                              (:cdfile, ap.get_cd, cdfile, DIR_CD, ["alpha", "cd"]),
                                              (:cmfile, ap.get_cm, cmfile, DIR_CM, ["alpha", "cm"]),
                                              # (:xupsepfile, ap.get_xupsep, xupsepfile, DIR_XUP, ["alpha", "xsep"]),
                                              # (:xlosepfile, ap.get_xlosep, xlosepfile, DIR_XLO, ["alpha", "xsep"]),
                                            ]

        if findfirst(x->x==field, keys(lbls))==nothing # Check if field wasn't prescribed by user

            col1, col2 = fun(polar)

            fname = joinpath(database_path, dir, file)

            if isfile()
                warn("Overwriting file $fname.")
            end

            # Create file
            f = open(fname, "w")

            println(f, headers[1], ",", headers[2])
            for rowi in 1:length(col1)
                println(f, col1[rowi], ",", col2[rowi])
            end

            close(f)

            # Add field
            push!(this_lbls, (field, file))
        end

    end

    return new_entry(; database_path=database_path, this_lbls...)
end

# ------------ INTERNAL FUNCTIONS ----------------------------------------------

end # END OF MODULE
