# AirfoilDatabase
Database for managing airfoil polar information.

# Structure
|         Folder              |         Description                            |
|:---------------------------:|:----------------------------------------------:|
| `database/`                 | Each file in this folder is the indexing of a database |
| `database/xy/`              | Airfoil contours. Points x,y must go
                                from trailing edge around the top, then around
                                the bottom and end back at the trailing edge.
                                The function `                     ` will
                                automatically sort the points if the contour
                                doesn't already follow this convention.        |
| `database/Cl/`              | Lift coefficient curves as function of AOA     |
| `database/Cd/`              | Drag coefficient curves as function of AOA     |
| `database/Cm/`              | Drag coefficient curves as function of AOA     |
| `database/xupsep/`          | Separation point on upper surface as function
                                of AOA                                         |
| `database/xlosep/`          | Separation point on lower surface as function
                                of AOA                                         |


# Authorship
  * Author            : Eduardo J Alvarez
  * Email             : Edo.AlvarezR@gmail.com
  * Website           : [edoalvarez.com](https://www.edoalvarez.com/)
  * Created           : Oct 2019
  * License           : MIT License
