#=##############################################################################
# DESCRIPTION
    Functions for database manipulation

# AUTHORSHIP
  * Author    : Eduardo J. Alvarez
  * Email     : Edo.AlvarezR@gmail.com
  * Created   : Jun 2020
  * License   : MIT
=###############################################################################

"""
    `new_database(path::String; index_file::String=DEF_NDXFL, mkpath_optargs=[], prompt=true, v_lvl=0)`

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

$(_lbls2prettystring())

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
    `new_entry(polar::AirfoilPrep.Polar; database_path::String=$(def_database), warn=true, index_file::String=$(DEF_NDXFL), lbls...)`

Adds a new entry to the database under `database_path` with indexing file
`index_file`. `lbls` are the labels of the entry (or columns of database), as
shown above (Fields is the name of the label).
"""
function new_entry(polar::ap.Polar; database_path::String=def_database,
                                    ext::String=".csv", warn=true, lbls...)

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
    xupsepfile = rflname*"-xupsep"*suff
    xlosepfile = rflname*"-xlosep"*suff

    # Create files and add them to the entry
    for (field, fun, file, dir, headers) in [ (:xyfile, ap.get_geometry, xyfile, DIR_XY, ["x", "y"]),
                                              (:clfile, ap.get_cl, clfile, DIR_CL, ["alpha", "cl"]),
                                              (:cdfile, ap.get_cd, cdfile, DIR_CD, ["alpha", "cd"]),
                                              (:cmfile, ap.get_cm, cmfile, DIR_CM, ["alpha", "cm"]),
                                              (:xupsepfile, ap.get_xsepup, xupsepfile, DIR_XUP, ["alpha", "xsep"]),
                                              (:xlosepfile, ap.get_xseplo, xlosepfile, DIR_XLO, ["alpha", "xsep"]),
                                            ]

        if findfirst(x->x==field, keys(lbls))==nothing # Check if field wasn't prescribed by user

            col1, col2 = fun(polar)

            fname = joinpath(database_path, dir, file)

            if isfile(fname) && warn
                @warn("Overwriting file $fname.")
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
