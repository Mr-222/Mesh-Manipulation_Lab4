// Polygon mesh manipulation starter code.

// for object rotation by mouse
int mouseX_old = 0;
int mouseY_old = 0;
PMatrix3D rot_mat;

// camera parameters
float camera_default = 6.0;
float camera_distance = camera_default;

boolean per_vertex_normal = false;

boolean display_edge = false;

boolean visualize_directed_edge = false;
Edge displayed_edge;

boolean random_color = false;

Mesh mesh;

PVector linearInterp(PVector start, PVector end, float t) {
  PVector diff = PVector.sub(end, start);
  return PVector.add(start, PVector.mult(diff, t));
}

void drawSpheres(Vertex v0, Vertex v1, Face f) {
  PVector face_centroid = f.centroid();
  var pos_v0 = new PVector(v0.x, v0.y, v0.z);
  var pos_v1 = new PVector(v1.x, v1.y, v1.z);
  PVector mid_pos = linearInterp(pos_v0, pos_v1, 0.5f);
  
  PVector diff = PVector.sub(face_centroid, mid_pos);
  diff.normalize();
  push();
  translate(diff.x * 0.1f, diff.y * 0.1f, diff.z * 0.1f);
  
  push();
  var pos1 = linearInterp(pos_v0, pos_v1, 2.2/6.0);
  translate(pos1.x, pos1.y, pos1.z);
  fill(255, 0, 0);
  sphere(0.15);
  pop();
  
  push();
  var pos2 = linearInterp(pos_v0, pos_v1, 3.2/6.0);
  translate(pos2.x, pos2.y, pos2.z);
  fill(255, 0, 0);
  sphere(0.1);
  pop();
  
  push();
  var pos3 = linearInterp(pos_v0, pos_v1, 3.9/6.0);
  translate(pos3.x, pos3.y, pos3.z);
  fill(255, 0, 0);
  sphere(0.07);
  pop();
  
  pop();
}

void setup()
{
  size (800, 800, OPENGL);
  rot_mat = (PMatrix3D) getMatrix();
  rot_mat.reset();
}

void draw()
{
  background (130, 130, 220);    // clear the screen to black

  perspective (PI*0.2, 1.0, 0.01, 1000.0);
  camera (0, 0, camera_distance, 0, 0, 0, 0, 1, 0);   // place the camera in the scene
  
  // create an ambient light source
  ambientLight (52, 52, 52);

  // create two directional light sources
  lightSpecular (0, 0, 0);
  directionalLight (150, 150, 150, -0.7, 0.7, -1);
  directionalLight (152, 152, 152, 0, 0, -1);
  
  pushMatrix();

  if (display_edge)
  // draw polygons with black edges
    stroke (0);  
  else
    noStroke();
  fill (200, 200, 200);          // set the polygon color to white
  
  ambient (200, 200, 200);
  specular (0, 0, 0);            // turn off specular highlights
  shininess (1.0);
  
  applyMatrix (rot_mat);   // rotate the object using the global rotation matrix
  
  // THIS IS WHERE YOU SHOULD DRAW YOUR MESH
  if (mesh != null) {
    for (Face f : mesh.faces) {
      beginShape();
      if (random_color)
        fill(f.col);
      for (Vertex v : f.verts) {
        if (per_vertex_normal) {
          PVector n = mesh.calculateVertexNormal(v);
          normal(n.x, n.y, n.z);
        }
        vertex(v.x, v.y, v.z);
      }
      endShape();
    }
    
    if (visualize_directed_edge) {
      Face f = displayed_edge.face;
      Vertex v0 = mesh.vertices.get(displayed_edge.vert_index);
      int local_index_v0 = f.verts.indexOf(v0);
      Vertex v1 = f.verts.get((local_index_v0 + 1) % f.verts.size());
      drawSpheres(v0, v1, f);
    }
  }
    
  popMatrix();
}

// remember where the user clicked
void mousePressed()
{
  mouseX_old = mouseX;
  mouseY_old = mouseY;
}

// change the object rotation matrix while the mouse is being dragged
void mouseDragged()
{
  if (!mousePressed)
    return;

  float dx = mouseX - mouseX_old;
  float dy = mouseY - mouseY_old;
  dy *= -1;

  float len = sqrt (dx*dx + dy*dy);
  if (len == 0)
    len = 1;

  dx /= len;
  dy /= len;
  PMatrix3D rmat = (PMatrix3D) getMatrix();
  rmat.reset();
  rmat.rotate (len * 0.005, dy, dx, 0);
  rot_mat.preApply (rmat);

  mouseX_old = mouseX;
  mouseY_old = mouseY;
}

// handle keystrokes
void keyPressed()
{
  if (key == CODED) {
    if (keyCode == UP) {         // zoom in
      camera_distance *= 0.9;
    }
    else if (keyCode == DOWN) {  // zoom out
      camera_distance /= 0.9;
    }
    return;
  }
  
  if (key == 'R') {
    rot_mat.reset();
    camera_distance = camera_default;
  }
  else if (key == '1') {
    mesh = read_mesh ("octa.ply");
  }
  else if (key == '2') {
    mesh = read_mesh ("cube.ply");
  }
  else if (key == '3') {
    mesh = read_mesh ("icos.ply");
  }
  else if (key == '4') {
    mesh = read_mesh ("dodeca.ply");
  }
  else if (key == '5') {
    mesh = read_mesh ("star.ply");
  }
  else if (key == '6') {
    mesh = read_mesh ("torus.ply");
  }
  else if (key == '7') {      
    mesh = read_mesh ("s.ply");
  }
  else if (key == 'f') {
    per_vertex_normal = !per_vertex_normal;
  }
  else if (key == 'e') {
    display_edge = !display_edge;
  }
  else if (key == 'v') {
    visualize_directed_edge = !visualize_directed_edge;
  }
  else if (key == 'n') {
    if (displayed_edge == null)
      return;
    displayed_edge = mesh.next(displayed_edge);
  }
  else if (key == 'p') {
    if (displayed_edge == null)
      return;
    displayed_edge = mesh.prev(displayed_edge);
  }
  else if (key == 'o') {
    if (displayed_edge == null)
      return;
    displayed_edge = mesh.opposite(displayed_edge);
  }
  else if (key == 's') {
    if (displayed_edge == null)
      return;
    displayed_edge = mesh.swing(displayed_edge);
  }
  else if (key == 'u') {
    if (displayed_edge == null)
      return;
    displayed_edge = mesh.unSwing(displayed_edge);
  }
  else if (key == 'd') {
    mesh = mesh.dual();
    // Initialze directed edge that will be visualized
    Face f0 = mesh.faces.get(0);
    displayed_edge = mesh.edges.get(new Pair<Vertex, Vertex>(f0.verts.get(0), f0.verts.get(1)));
  }
  else if (key == 'g') {
    mesh = mesh.midPointSubdivide();
    // Initialze directed edge that will be visualized
    Face f0 = mesh.faces.get(0);
    displayed_edge = mesh.edges.get(new Pair<Vertex, Vertex>(f0.verts.get(0), f0.verts.get(1)));
  }
  else if (key == 'c') {
    mesh = mesh.catmullSubdivide();
    // Initialze directed edge that will be visualized
    Face f0 = mesh.faces.get(0);
    displayed_edge = mesh.edges.get(new Pair<Vertex, Vertex>(f0.verts.get(0), f0.verts.get(1)));
  }
  else if (key == 'r') {
    mesh = mesh.applyNoise();
    // Initialze directed edge that will be visualized
    Face f0 = mesh.faces.get(0);
    displayed_edge = mesh.edges.get(new Pair<Vertex, Vertex>(f0.verts.get(0), f0.verts.get(1)));
  }
  else if (key == 'l') {
    mesh = mesh.laplacian(.6f);
    // Initialze directed edge that will be visualized
    Face f0 = mesh.faces.get(0);
    displayed_edge = mesh.edges.get(new Pair<Vertex, Vertex>(f0.verts.get(0), f0.verts.get(1)));    
  }
  else if (key == 't') {
    mesh = mesh.taubin(0.6307f, -0.67315f);
    // Initialze directed edge that will be visualized
    Face f0 = mesh.faces.get(0);
    displayed_edge = mesh.edges.get(new Pair<Vertex, Vertex>(f0.verts.get(0), f0.verts.get(1)));    
  }
  else if (key == 'w') {
    random_color = !random_color;
    if (random_color && mesh != null)
      mesh.randomColors();
  }
}
