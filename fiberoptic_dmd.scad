/**
 BSD 3-Clause License
 
 Copyright (c) 2023, Null Builds
 
 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions are met:
 
 1. Redistributions of source code must retain the above copyright notice, this
    list of conditions and the following disclaimer.
 
 2. Redistributions in binary form must reproduce the above copyright notice,
    this list of conditions and the following disclaimer in the documentation
    and/or other materials provided with the distribution.
 
 3. Neither the name of the copyright holder nor the names of its
    contributors may be used to endorse or promote products derived from
    this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
 FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
 CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
 OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

/* [Preview Options] */

// Which part to render
part = "matrix_mount"; // [matrix_mount:LED Matrix Mount,frame:Frame,bezel:Bezel]

// Adjusts the quality of curved surfaces at the cost of rendering performance
quality = "low"; // [low:Low,medium:Medium,high:High]

/* [Model Options] */

// How many rows the display has
display_rows = 8;

// How many columns the display has
display_columns = 8;

// The pitch (spacing) of the display dots in mm
display_pitch = 1.9;

// The diameter of the holes the filaments will be pressed into in mm
filament_hole_diameter = 1.25;

// The thickness walls of the filament frame in mm
frame_wall_thickness = 2;

// The thickness of the clear plastic serving as the display surface in mm
display_surface_thickness = 1;

// Adjust the quality of curved surfaces based on the "quality" variable.
$fa = quality == "low" ? 6 : quality == "medium" ? 1 : 0.1;
$fs = quality == "low" ? 2 : quality == "medium" ? 1 : 0.1;

build_part();

/**
 * A small value used during union and difference operations to create a slight overlap between
 * bodies for the purpose of preventing imperceptibly thin walls caused by rounding errors.
 * 
 * @return the value
 */
function epsilon() = 0.01;

/**
 * Switches which part is shown based on the value of the "part" variable.
 * 
 * <p>This function allows multiple parts to be rendered from a single file. It also meets
 * Thingiverse's customizer requirements should I wish to upload there.
 */
module build_part() {
  frame_width = display_columns * display_pitch + frame_wall_thickness * 2;
  frame_height = display_rows * display_pitch + frame_wall_thickness * 2;
  frame_depth = 10;
  
  if (part == "matrix_mount") {
    assert(filament_hole_diameter < 4, "filament_hole_diameter must be less than 4mm.");
    
    rows = 8;
    columns = 8;
    pitch = 4;
    wall_thickness = 2;
    width = columns * pitch + wall_thickness * 2;
    height = rows * pitch + wall_thickness * 2;
    
    translate([-width / 2, -height / 2, 0]) {
      led_matrix_mount(
          filament_hole_diameter = filament_hole_diameter,
          rows = rows,
          columns = columns,
          pitch = pitch,
          wall_thickness = wall_thickness,
          wall_height = 2,
          clip_width = 10,
          clip_height = 4.8,
          clip_reach = 0.5,
          filament_depth = 10,
          light_gate_thickness = 1,
          light_gate_diameter = 0.9
      );
    }
  } else if (part == "frame") {
    translate([-frame_width / 2, -frame_height / 2, 0]) {
      frame(
          filament_hole_diameter = filament_hole_diameter,
          pitch = display_pitch,
          rows = display_rows,
          columns = display_columns,
          wall_thickness = frame_wall_thickness,
          height = frame_depth
      );
    }
  } else if (part == "bezel") {
    allowance = 0.3;
    
    size_bezel_thickness = 2;
    width = frame_width + allowance + size_bezel_thickness * 2;
    height = frame_height + allowance + size_bezel_thickness * 2;
    
    translate([-width / 2, -height / 2, 0]) {
      bezel(
          inner_width = frame_width + allowance,
          inner_height = frame_height + allowance,
          inner_depth = frame_depth / 2,
          display_width = display_columns * display_pitch + allowance,
          display_height = display_rows * display_pitch + allowance,
          front_bezel_thickness = 1,
          size_bezel_thickness = size_bezel_thickness,
          clip_width = 5,
          clip_height = frame_depth / 2 + display_surface_thickness,
          clip_reach = 0.5
      );
    }
  }
}

/**
 * Creates the frame to hold the fiberoptic filaments.
 * 
 * @param filament_hole_diameter the diameter of the hole for the filament in mm
 * @param pitch the pitch of the dots in mm
 * @param rows the number of rows of dots
 * @param columns the number of columns of dots
 * @param wall_thickness the thickness of the outside walls in mm
 * @param height the height of the frame in mm
 */
module frame(filament_hole_diameter, pitch, rows, columns, wall_thickness, height) {
  assert(pitch > filament_hole_diameter, "filament_hole_diameter must be less than pitch.");
  
  size = [
    pitch * columns + wall_thickness * 2,
    pitch * rows + wall_thickness * 2
  ];
  
  linear_extrude(height = height, slices = 1) {
    difference() {
      square(size = size);
      translate([wall_thickness, wall_thickness]) {
        dot_grid(
            dot_diameter = filament_hole_diameter,
            pitch = pitch,
            rows = rows,
            columns = columns
        );
      }
    }
  }
}

/**
 * The mount for attaching the LED matrix to the filaments.
 * 
 * @param filament_hole_diameter the diameter of the holes for each filament in mm
 * @param rows the number of rows of dots
 * @param columns the number of columns of dots
 * @param pitch the pitch of the dots in mm
 * @param wall_thickness the thickness of the walls around the LED matrix in mm
 * @param wall_height the height of the walls around the LED matrix in mm
 * @param clip_width the width of the clips in mm
 * @param clip_height the height of the clips in mm
 * @param clip_reach the distance the clips reach over the other part in mm
 * @param filament_depth the depth the filaments can be inserted into the part in mm
 * @param light_gate_thickness the thickness of panel between the filaments and LEDs in mm
 * @param light_gate_diameter the diameter of the holes allowing light into the filaments in mm
 */
module led_matrix_mount(
    filament_hole_diameter,
    rows,
    columns,
    pitch,
    wall_thickness,
    wall_height,
    clip_width,
    clip_height,
    clip_reach,
    filament_depth,
    light_gate_thickness,
    light_gate_diameter) {
  outer_width = columns * pitch + wall_thickness * 2;
  outer_height = rows * pitch + wall_thickness * 2;
  inner_width = outer_width - wall_thickness * 2;
  inner_height = outer_height - wall_thickness * 2;
  
  union() {
    // Filament holding plate
    linear_extrude(height = filament_depth, slices = 1) {
      hole_plate_profile(
          hole_diameter = filament_hole_diameter,
          rows = rows,
          columns = columns,
          pitch = pitch,
          bezel = wall_thickness
      );
    }
    
    translate([0, 0, filament_depth - epsilon()]) {
      // Light gate
      linear_extrude(height = light_gate_thickness, slices = 1) {
        hole_plate_profile(
            hole_diameter = light_gate_diameter,
            rows = rows,
            columns = columns,
            pitch = pitch,
            bezel = wall_thickness
        );
      }
      
      translate([0, 0, light_gate_thickness - epsilon()]) {
        // Walls
        linear_extrude(height = wall_height, slices = 1) {
          hollow_rectangle(
              outer_size = [outer_width, outer_height],
              inner_size = [inner_width, inner_height]
          );
        }
        
        // Tabs
        for(tab = [0:1]) {
          translate([outer_width * tab, outer_height / 2, wall_height - epsilon()]) {
            rotate([90, 0, tab * 180]) {
              linear_extrude(height = clip_width, slices = 1, center = true) {
                clip_profile(height = clip_height, thickness = wall_thickness, reach = clip_reach);
              }
            }
          }
        }
      }
    }
  }
}

/**
 * Creates the display's bezel.
 * 
 * @param inner_width the inner width of the bezel in mm
 * @param inner_height the inner height of the bezel in mm
 * @param inner_depth the depth of the bezel in mm
 * @param display_width the width of the visible display in mm
 * @param display_height the height of the visible display in mm
 * @param front_bezel_thickness the thickness of the front bezel face in mm
 * @param size_bezel_thickness the thickness of the front bezel walls in mm
 * @param clip_width the width of the clips in mm
 * @param clip_height the height of the clips in mm
 * @param clip_reach how far the clips engage with the other part in mm
 */
module bezel(
    inner_width,
    inner_height,
    inner_depth,
    display_width,
    display_height,
    front_bezel_thickness,
    size_bezel_thickness,
    clip_width,
    clip_height,
    clip_reach) {
  front_bezel_size = (inner_width - display_width) / 2;
  front_width = display_width + front_bezel_size * 2;
  front_height = display_height + front_bezel_size * 2;
  outer_width = inner_width + size_bezel_thickness * 2;
  outer_height = inner_height + size_bezel_thickness * 2;
  outer_thickness = inner_depth + front_bezel_thickness;
  chamfer_radius = size_bezel_thickness;
  
  union() {
    difference() {
      translate([outer_width, 0, 0]) {
        rotate([0, 0, 90]) {
          translate([outer_height, 0, 0]) {
            rotate([0, -90, 0]) {
              intersection() {
                translate([0, outer_width, 0]) {
                  rotate([90, 0, 0]) {
                    linear_extrude(height = outer_width, slices = 1) {
                      bezel_side_profile(
                          width = outer_height,
                          depth = outer_thickness,
                          chamfer_radius = chamfer_radius
                      );
                    }
                  }
                }
                
                linear_extrude(height = outer_height, slices = 1) {
                  bezel_side_profile(
                      width = outer_width,
                      depth = outer_thickness,
                      chamfer_radius = chamfer_radius
                  );
                }
              }
            }
          }
        }
      }
      
      // Display hole
      translate([chamfer_radius + front_bezel_size, chamfer_radius + front_bezel_size, -epsilon()]) {
        cube(size = [display_width, display_height, outer_thickness + epsilon() * 2]);
      }
      
      // Inner hole
      translate([chamfer_radius, chamfer_radius, front_bezel_thickness]) {
        cube(size = [inner_width, inner_height, inner_depth + epsilon()]);
      }
    }
    
    // Clips
    for(clip = [0:1]) {
      translate([clip * outer_width, outer_height / 2, outer_thickness - epsilon()]) {
        rotate([90, 0, clip * 180]) {
          linear_extrude(height = clip_width, slices = 1, center = true) {
            clip_profile(height = clip_height, thickness = size_bezel_thickness, reach = clip_reach);
          }
        }
      }
    }
  }
}

/**
 * The 2D profile of the bezel.
 * 
 * @param width the width of the bezel in mm
 * @param depth the depth of the bezel in mm
 * @param chamfer_radius the radius of the bezel's chamfer in degrees
 */
module bezel_side_profile(width, depth, chamfer_radius) {
  points = [
    [chamfer_radius, 0],
    [depth, 0],
    [depth, width],
    [chamfer_radius, width],
    [0, width - chamfer_radius],
    [0, chamfer_radius]
  ];
  
  polygon(points = points);
}

/**
 * The side profile of the clips.
 * 
 * @param height the height of the clips in mm
 * @param thickness the thickness of the clip body in mm
 * @param reach the distance of the clip overhang in mm
 */
module clip_profile(height, thickness, reach) {
  total_height = height + reach;
  
  points = [
    [0, 0],
    [thickness, 0],
    [thickness, height],
    [thickness + reach, height],
    [thickness + reach, height + reach],
    [0, height + reach + thickness + reach]
  ];
  
  polygon(points = points);
}

/**
 * Creates a 2D profile of a plate with a grid of holes.
 * 
 * @param hole_diameter the diameter of the holes in mm
 * @param rows the number of rows of holes
 * @param columns the number of columns of holes
 * @param pitch the pitch of the holes in mm
 * @param bezel the distance from the outer holes to the plate edge in mm
 */
module hole_plate_profile(hole_diameter, rows, columns, pitch, bezel) {
  overal_width = pitch * columns + bezel * 2;
  overal_height = pitch * rows + bezel * 2;
  
  difference() {
    square(size = [overal_width, overal_height]);
    translate([bezel, bezel]) {
      dot_grid(dot_diameter = hole_diameter, pitch = pitch, rows = rows, columns = columns);
    }
  }
}

/**
 * Creates a 2D profile of a grid of dots.
 * 
 * @param dot_diameter the diameter of each dot in mm
 * @param pitch the pitch of the dots in mm
 * @param rows the number of rows of dots
 * @param columns the number of columns of dots
 */
module dot_grid(dot_diameter, pitch, rows, columns) {
  for(row = [0:rows-1]) {
    for(column = [0:columns-1]) {
      translate([pitch * column + pitch / 2, pitch * row + pitch / 2]) {
        circle(d = dot_diameter);
      }
    }
  }
}

/**
 * Creates a rectangle with a rectangular hole.
 * 
 * @param outer_size a 2D list containing the width and height of the outer rectangle in mm
 * @param inner_size a 2D list containing the width and height of the inner rectangel in mm
 */
module hollow_rectangle(outer_size, inner_size) {
  difference() {
    square(size = outer_size);
    translate([(outer_size.x - inner_size.x) / 2, (outer_size.y - inner_size.y) / 2]) {
      square(size = inner_size);
    }
  }
}
