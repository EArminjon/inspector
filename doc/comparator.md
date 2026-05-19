# Description

I'm trying to build an overlay for my inspector that behaves like the overlay in Figma.

The idea is that lines should appear between the base component and the target comparison component to visually show
that the two components are linked.

# Glossary

* `#`: limits of a component
* `A`: a base component
* `B`: a target comparison component
* `|`: a solid line
* `.`: a dotted line

## Line Rules

* **Solid lines** should always start from the center of one side of a component and end at the center of the
  corresponding side of the other component.

* **Dotted lines** should always start from an edge of component B and connect to the endpoint of a solid line.

# Use Case 1

In this use case, components A and B are aligned but do not have the same size.
Three solid lines are required to display the distance between the two components, along with two dotted lines to show
their alignment.

### Before

```text
                     #########
                     #       #       
                     #   A   #       
                     #       #       
                     #########
                                    
                                    
                                    
                                    
               ##################### 
               #                   #
               #         B         #
               #####################
```

### After

```text
                     #########
                     #       #       
               ______#   A   #______       
               .     #       #     . 
               .     #########     .
               .         |         .
               .         |         .
               .         |         .
               .         |         .
               #####################
               #                   #
               #         B         #
               #####################
```

# Use Case 2

In this use case, components A and B are separated and not aligned.
Two dotted lines and two solid lines are required to display the distances and alignment relationship between the
components.

### Before

```text
                                             #########
                                             #       #       
                                             #   A   #       
                                             #       #       
                                             #########
                                    
                                    
                                    
                                    
               ##################### 
               #                   #
               #         B         #
               #####################
```

### After

```text
                                             #########
                                             #       #       
                                   __________#   A   #       
                                   .         #       #       
                                   .         #########
                                   .             |
                                   .             |
                                   .             |
                                   .             |
               #####################.............| 
               #                   #
               #         B         #
               #####################
```

# Use Case 3

In this use case, components A and B are aligned.
There is no need for dotted alignment lines — only a solid line is required to display the distance between the two
components.

### Before

```text
                     #########
                     #       #       
                     #   A   #       
                     #########
                                      
                                      
                                      
                                      
                     #########
                     #       #       
                     #   B   #       
                     #########
```

### After

```text
                     #########
                     #       #       
                     #   A   #       
                     #########
                         |            
                         |            
                         |            
                         |            
                     #########
                     #       #       
                     #   B   #       
                     #########
```

# Use Case 4

In this use case, component A is inside component B.
There is no need to display dotted alignment lines, only solid lines are required to show the distances between the
edges.

### Before

```text
                    
           ###############################
           #                             #
           #                             #
           #          #########          #
           #          #       #          #
           #          #   A   #          #
           #          #       #          #
           #          #########          #
           #                             #
           #                        B    #
           #                             #
           ###############################
```

### After

```text
                    
           ###############################
           #              |              #
           #              |              #
           #          #########          #
           #          #       #          #
           #__________#   A   #_________ #
           #          #       #          #
           #          #########          #
           #              |              #
           #              |         B    #
           #              |              #
           ###############################
```

# Use Case 5

In this use case, components A and B are touching diagonally at corners.
No dotted lines, solid lines or distance indicators must be displayed.

Note: The “before” and “after” states are not very explicit because this use case is difficult to illustrate with ASCII
art. The idea is that the two components only touch at a corner, so there is no need to display any lines indicating
distance or alignment between them.

### Before

```text
                     #########
                     #       #       
                     #   A   #       
                     #       #       
            ##################
            #       #
            #   B   #
            #       #
            #########
```

### After

```text
                     #########
                     #       #       
                     #   A   #       
                     #       #       
            ##################
            #       #
            #   B   #
            #       #
            #########
```

# Use Case 6

In this use case, components A and B are aligned but separated.
Two solid lines and two dotted lines are displayed.

### Before

```text
                                 #########
                                 #       #       
                                 #   A   #       
                                 #       #       
           #########             #########
           #       #
           #   B   #
           #       #
           #########
```

### After

```text
                                 #########
                                 #       #       
                   _____________ #   A   #       
                   .             #       #       
           #########             #########
           #       #                 |
           #   B   #                 |
           #       #                 |
           #########.................|
```

# Use Case 7

In this use case, components A and B are edge to edge and aligned.
No dotted lines or solid lines are required to show the distance.

### Before

```text
                 #########
                 #       #       
                 #   A   #       
                 #       #       
                 #########
                 #       #       
                 #   B   #       
                 #       #       
                 #########
```

### After

```text
                 #########
                 #       #       
                 #   A   #       
                 #       #       
                 #########
                 #       #       
                 #   B   #       
                 #       #       
                 #########
```

# Use Case 8

In this use case, components A and B are aligned but A is bigger than B.
One solid line and 1 dotted line are displayed.

### Before

```text
                 #########       #########
                 #       #       #   B   #
                 #       #       #########
                 #       #       
                 #       #
                 #   A   #
                 #       #
                 #       #       
                 #       #       
                 #       #       
                 #########
```

### After

```text
                 #########       #########
                 #       #       #   B   #
                 #       #       #########
                 #       #           .
                 #       #           .
                 #   A   #____________
                 #       #
                 #       #       
                 #       #       
                 #       #       
                 #########
```
