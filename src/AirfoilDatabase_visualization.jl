#=##############################################################################
# DESCRIPTION
    Functions for database visualization

# AUTHORSHIP
  * Author    : Eduardo J. Alvarez
  * Email     : Edo.AlvarezR@gmail.com
  * Created   : Jul 2020
  * License   : MIT
=###############################################################################

function visualize(; database_path::String=def_database,
                        index_file::String=DEF_NDXFL, plot_backend=plt.plotly)

    # Read database
    db  = jdb.loadtable(joinpath(database_path, index_file))

    # What to plot on every axis
    xaxis = :alpha
    yaxiss = [:re, :ma, :ncrit]
    zaxiss = [:clfile, :cdfile, :cmfile, :xupsepfile, :xlosepfile]

    labels = Dict(    :alpha => "Angle of attack",    # Label of each axis alternative
                      :re    => "Reynolds number",
                      :ma    => "Mach number",
                      :ncrit => "Turbulence parameter",
                      :clfile=> "Lift coefficient",
                      :cdfile=> "Drag coefficient",
                      :cmfile=> "Moment coefficient",
                      :xupsepfile=> "Separation point x",
                      :xlosepfile=> "Separation point x",
                      )
    labelsbttn = Dict(:alpha => "α",                  # Labels on buttons
                      :re    => "Reynolds number",
                      :ma    => "Mach number",
                      :ncrit => "Turbulence ncrit",
                      :clfile=> "Cl",
                      :cdfile=> "Cd",
                      :cmfile=> "Cm",
                      :xupsepfile=> "xsep upper",
                      :xlosepfile=> "xsep lower",
                      )
    lblbttn_2_field = Dict( (val, key) for (key, val) in labelsbttn) # Button labels to field


    # GUI-enabled plot
    # plotly()
    # plotlyjs()
    # pyplot()
    # gr()
    plot_backend()

    plotobj = nothing
    ite = 0

    # TODO: add a throttle
    mp = ntrct.@manipulate for     airfoil in ntrct.togglebuttons( reverse(unique(jdb.select(db, :Airfoil))), label="Airfoil" ),
                                        re in ntrct.slider( unique(jdb.select(db, :Re)), label="Reynolds Number" ),
                                        ma in ntrct.slider( unique(jdb.select(db, :Mach)), label="Mach Number" ),
                                     ncrit in ntrct.slider( unique(jdb.select(db, :Ncrit)), label="Turbulence ncrit" ),
                                     diffe in ntrct.slider( unique(jdb.select(db, :Differentiator)), label="ID" ),
                                     _yaxis in ntrct.togglebuttons( [labelsbttn[ax] for ax in yaxiss], label="y-axis" ),
                                     _zaxis in ntrct.togglebuttons( [labelsbttn[ax] for ax in zaxiss], label="z-axis" )

        yaxis = lblbttn_2_field[_yaxis]
        println(_yaxis, "\t", yaxis)
        zaxis = lblbttn_2_field[_zaxis]
        first_flag = true

        # Convert axes to column names (headers)
        ycolname = Symbol(FIELD2_HEADER[yaxis])
        zcolname = Symbol(FIELD2_HEADER[zaxis])
        ycoli = findfirst(x->x==ycolname, eltype(db.columns_buffer).parameters[1])

        # Filter file names to read
        filter_crit = [(:Airfoil, airfoil), (:Re, re), (:Mach, ma),
                                                (:Ncrit, ncrit), (:Differentiator, diffe)]
        filter_fun(nt) = prod([getfield(nt, field)==val for (field, val) in filter_crit
                                                            if field != Symbol(ycolname)])

        entries = jdb.filter(filter_fun, db)

        # Range of z to color
        zminclr, zmaxclr =  zaxis==:clfile ?     (-1.5, 2.0)   :
                            zaxis==:cdfile ?     (0, 0.2)      :
                            zaxis==:cmfile ?     (-0.02, 0.02) :
                            zaxis==:xupsepfile ? (1, 0.25)     :
                            zaxis==:xlosepfile ? (1, 0.25)     :
                                                 (-1, 1)

        # Iterate over rows reading polar files and plotting them
        for rowi in 1:length(entries)
            entry = entries[rowi]
            filename = entry[zcolname]
            yval = entry[ycoli]

            # Read data
            data = CSV.read(joinpath(database_path, DIRS[zaxis], filename))

            # Selects plot function to use
            if first_flag
                plotfun = plt.scatter
                first_flag = false
            else
                # plotfun = plt.scatter
                plotfun = plt.scatter!
            end

            # Color each point according the z value
            auxs = (zmaxclr .- data[!, 2]) / (zmaxclr - zminclr)
            auxs = [aux > 1 ? 1 : aux<0 ? 0 : aux for aux in auxs]
            clrs = collect((1-aux, 0, aux) for aux in auxs)

            plotobj = plotfun(data[!, 1], yval*ones(size(data, 1)), data[!, 2];
                                        label="",
                                        markerstrokealpha=0.2, markeralpha=0.75,
                                        markersize=1,
                                        xlabel=labels[xaxis], ylabel=labels[yaxis], zlabel=labels[zaxis],
                                        color=[plt.RGB(clr...) for clr in clrs],
                                        edgecolor=[plt.RGB(clr...) for clr in clrs]
                                    )
        end

        display(ite)
        ite += 1

        # display(plotobj)
        plotobj
    end
end
