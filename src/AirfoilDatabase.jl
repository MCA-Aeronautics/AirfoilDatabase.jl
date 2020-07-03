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
import CSV
import JuliaDB
import Plots
import Interact

const jdb = JuliaDB
const plt = Plots
const ntrct = Interact

# ------------ FLOW CODES ------------------------------------------------------
# https://github.com/byuflowlab/AirfoilPrep.jl
import AirfoilPrep
const ap = AirfoilPrep

# ------------ GLOBAL VARIABLES ------------------------------------------------
const module_path = splitdir(@__FILE__)[1]                   # Path to this module
const def_database = joinpath(module_path, "../database/")   # Path to default database

# ------------ DATA STRUCTURE --------------------------------------------------
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

"Convert LBLS into a DataFrame"
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

"Convert LBLS into a pretty String"
function _lbls2prettystring()
    b = IOBuffer();
    t = TextDisplay(b);
    display(t, LBLS);
    s = String(take!(b))
    return s
end

# ------------ HEADERS ---------------------------------------------------------
# Load headers
for header_name in ["manipulation", "visualization"]
    include("AirfoilDatabase_"*header_name*".jl")
end


end # END OF MODULE
