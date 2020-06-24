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
const DEF_NDXFL = "default_index.csv" # Default indexing file name
const RQRD = "required"     # Default value for requiered fields
const PTNL_S = " "          # Default value for optional String fields
const PTNL_R = 0            # Default value for optional Real fields
const PTNL_I = 0            # Default value for optional Int fields
const PTNL_B = true         # Default value for optional Boolean fields
                            # Labels of each database entry
const LBLS = OrderedDict(#  hash_key        => (csv_header, default_value, type)
                            :airfoilname    => ("Airfoil", RQRD, String),   # Airfoil name
                            :re             => ("Re", PTNL_R, Real),        # Reynolds number
                            :ma             => ("Mach", PTNL_R, Real),      # Mach number
                            :npanels        => ("Panels", PTNL_I, Int),     # Number of panels (XFOIL)
                            :ncrit          => ("Ncrit", PTNL_I, Int),      # XFOIL Ncrit parameter
                            :deg            => ("Degrees", PTNL_B, Bool),   # XFOIL Ncrit parameter
                            :xyfile         => ("xy file", RQRD, String),   # Airfoil contour file
                            :clfile         => ("Cl file", PTNL_S, String), # Cl file
                            :cdfile         => ("Cd file", PTNL_S, String), # Cd file
                            :cmfile         => ("Cm file", PTNL_S, String), # Cm file
                            :xupsepfile     => ("xupsep file", PTNL_S, String),# xupsep file
                            :xlosepfile     => ("xlosep file", PTNL_S, String),# xlosep file
                            :diff           => ("Differentiator", PTNL_I, Int),# Differentiator number (for accepting duplicates)
                        )
const RQRD_FIELDS = [key for (key, val) in LBLS  if val[2]==RQRD]


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

function new_entry(; database_path::String=def_database,
                        index_file::String=DEF_NDXFL, lbls...)

    # Check that all required fields where given
    for field in RQRD_FIELDS
        if findfirst(x->x==field, keys(lbls))==nothing
            error("Required field $field was not given!")
        end
    end

    # Test that all fields are the correct type
    for (field, val) in LBLS
        if (findfirst(x->x==field, keys(lbls)) != nothing
            && typeof(lbls[findfirst(x->x==field, keys(lbls))]) != val[3])
            error("Expected type $(val[3]) under field $(field);"*
                        "got $(lbls[findfirst(x->x==field, keys(lbls))])"*
                        " (type $(typeof(lbls[findfirst(x->x==field, keys(lbls))])).")
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

end # END OF MODULE
