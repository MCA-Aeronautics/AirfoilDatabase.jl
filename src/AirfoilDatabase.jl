#=##############################################################################
# DESCRIPTION
    Database for managing airfoil polar information.

# AUTHORSHIP
  * Author    : Eduardo J. Alvarez
  * Email     : Edo.AlvarezR@gmail.com
  * Created   : Jun 2020
  * License   : MIT
=###############################################################################

module AirfoilDatabase

import DataStructures: OrderedDict

const DEF_NDXFL = "default_index.csv" # Default indexing file name
const DEF_XYDIR = "xy"      # Default xy directory
const DEF_CLDIR = "Cl"      # Default Cl directory
const DEF_CDDIR = "Cd"      # Default Cd directory
const DEF_CMDIR = "Cm"      # Default Cm directory
const DEF_XUPDIR = "xupsep" # Default xupsep directory
const DEF_XLODIR = "xlosep" # Default xlosep directory
const RQRD = "required"     # Default value for requiered fields
const PTNL_S = ""           # Default value for optional String fields
const PTNL_R = 0            # Default value for optional Real fields
const PTNL_I = 0            # Default value for optional Real fields
                            # Labels of each database entry
const LBL = OrderedDict(#   hash_key        => (csv_header, default_value, type)
                            :rflname        => ("Airfoil", RQRD, String),   # Airfoil name
                            :re             => ("Re", PTNL_R, Real),        # Reynolds number
                            :ma             => ("Mach", PTNL_R, Real),      # Mach number
                            :npanels        => ("Panels", PTNL_I, Int),     # Number of panels (XFOIL)
                            :ncrit          => ("Ncrit", PTNL_I, Int),      # XFOIL Ncrit parameter
                            :filexy         => ("xy file", RQRD, String),   # Airfoil contour file
                            :filecl         => ("Cl file", PTNL_S, String), # Cl file
                            :filecd         => ("Cd file", PTNL_S, String), # Cd file
                            :filecm         => ("Cm file", PTNL_S, String), # Cm file
                            :filexupsep     => ("xupsep file", PTNL_S, String),# xupsep file
                            :filexlosep     => ("xlosep file", PTNL_S, String),# xlosep file
                            :diff           => ("Differentiator", PTNL_I, Int),# Differentiator number (for accepting duplicates)
                        )

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
    for dir in [DEF_XYDIR, DEF_CLDIR, DEF_CDDIR, DEF_CMDIR, DEF_XUPDIR, DEF_XLODIR]
        mkpath(joinpath(path, dir); mkpath_optargs...)
    end

    # Create default indexing file
    f = open(joinpath(path, index_file), "w")

    for (coli, (key, val)) in enumerate(LBL)
        print(f, val[1])
        print(f, coli==length(LBL) ? "\n" : ",")
    end

    close(f)

    return joinpath(path, index_file)
end



end # END OF MODULE
