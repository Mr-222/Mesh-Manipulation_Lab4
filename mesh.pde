// Read polygon mesh from .ply file
//
// You should modify this routine to store all of the mesh data
// into a mesh data structure instead of printing it to the screen.

class Mesh {
  public ArrayList<Vertex> vertices;
  public ArrayList<Face> faces;
  public HashMap<Pair<Vertex, Vertex>, Edge> edges;
  
  public Mesh() {
    vertices = new ArrayList<>();
    faces = new ArrayList<>();
    edges = new HashMap<>();
  }
  
  public Mesh(ArrayList<PVector> v_positions, ArrayList<ArrayList<Integer>> face_indices) {
    vertices = new ArrayList<>();
    faces = new ArrayList<>();
    edges = new HashMap<>();
    
    // Read in the vertices
    for (PVector v_pos : v_positions) {
      Vertex v = new Vertex(v_pos);
      this.vertices.add(v);
    }
    
    // Read in the faces
    for (int i = 0; i < face_indices.size(); ++i) {
      Face f = new Face();
      this.faces.add(f);
      
      // Get the number of vertices for this face
      ArrayList<Integer> curr_face = face_indices.get(i);
      int nverts = curr_face.size();
      for (int k = 0; k < nverts; ++k) {
        // Face and Vertex info 
        Vertex v = this.vertices.get(curr_face.get(k));
        v.one_face = f;
        f.verts.add(v);
        
        // Edge info
        var e = new Edge();
        e.face = f;
        int start_vert_index = (k == 0) ? curr_face.get(nverts - 1) : curr_face.get(k - 1);
        e.vert_index = start_vert_index;
        this.edges.put(new Pair<Vertex, Vertex>(this.vertices.get(start_vert_index), v), e);
      }
    }
    
    // Find opposite edges
    for (Face f : this.faces) {
      int num_verts = f.verts.size();
      for (int i = 0; i < num_verts; ++i) {
        // opposite edge
        int start_index = (i + 1) % num_verts;
        int end_index = i;
        f.opposites.add(this.edges.get(new Pair<Vertex, Vertex>(f.verts.get(start_index), f.verts.get(end_index))));
      }
    }
  }
  
  public PVector calculateVertexNormal(Vertex v) {
    var n = new PVector(0, 0, 0);
    
    for (Face f : faces) {
      if (f.verts.contains(v)) {
        PVector face_normal = f.calculateNormal();
        n.add(face_normal);
      }
    }
    n.normalize();
    
    return n;
  }
  
  public Edge next(Edge e) {
    Face f = e.face;
    Vertex v = this.vertices.get(e.vert_index);
    int local_index = f.verts.indexOf(v);
    int local_next_first_index = (local_index + 1) % f.verts.size();
    int local_next_second_index = (local_next_first_index + 1) % f.verts.size();
    
    return this.edges.get(new Pair<Vertex, Vertex>(f.verts.get(local_next_first_index), f.verts.get(local_next_second_index)));
  }
  
  public Edge prev(Edge e) {
    Face f = e.face;
    Vertex v = this.vertices.get(e.vert_index);
    int local_index = f.verts.indexOf(v);
    int local_prev_first_index = (local_index - 1) < 0 ? f.verts.size() - 1 : local_index - 1;
    
    return this.edges.get(new Pair<Vertex, Vertex>(f.verts.get(local_prev_first_index), v));
  }
  
  public Edge opposite(Edge e) {
    Face f = e.face;
    Vertex v = this.vertices.get(e.vert_index);
    int local_index = f.verts.indexOf(v);
    
    return f.opposites.get(local_index);
  }
  
  public Edge swing(Edge e) {
    Edge temp = this.opposite(e);
    temp = this.next(temp);
    
    return temp;
  }
  
  public Edge unSwing(Edge e) {
    Edge temp = this.prev(e);
    temp = this.opposite(temp);
    
    return temp;
  }
  
  private Edge edgeFromVertex(Vertex v) {
    Face f = v.one_face;
    int local_index = f.verts.indexOf(v);
    int local_next_index = (local_index + 1) % f.verts.size();
    
    return edges.get(new Pair<Vertex, Vertex>(v, f.verts.get(local_next_index)));
  }
  
  public Mesh dual() {
    ArrayList<PVector> dual_vertices = new ArrayList<>();
    ArrayList<ArrayList<Integer>> dual_faces = new ArrayList<>();
    
    for (Vertex v : this.vertices) {
      // Each vertex of original mesh creates a face in dual mesh by swinging
      ArrayList<Integer> curr_face = new ArrayList<>();
      Edge e_start = this.edgeFromVertex(v);
      Edge e = e_start;
      do {
        PVector dual_v = e.face.centroid();
        int index = dual_vertices.indexOf(dual_v);
        if (index == -1) {
          curr_face.add(dual_vertices.size());
          dual_vertices.add(dual_v);
        }
        else
          curr_face.add(index);
          
        e = this.swing(e);
      } while (e != e_start);
      
      dual_faces.add(curr_face);
    }
    
    return new Mesh(dual_vertices, dual_faces);
  }
}

Mesh read_mesh (String filename)
{
  var mesh = new Mesh();
  
  String[] words;
  
  String lines[] = loadStrings(filename);
  
  words = split (lines[0], " ");
  int num_vertices = int(words[1]);
  println ("number of vertices = " + num_vertices);
  
  words = split (lines[1], " ");
  int num_faces = int(words[1]);
  println ("number of faces = " + num_faces);
  
  // read in the vertices
  for (int i = 0; i < num_vertices; i++) {
    words = split (lines[i+2], " ");
    float x = float(words[0]);
    float y = float(words[1]);
    float z = float(words[2]);
    println ("vertex = " + x + " " + y + " " + z);
    
    var v = new Vertex(x, y, z);
    v.x = x;
    v.y = y;
    v.z = z;
    mesh.vertices.add(v);
  }
  
  // read in the faces
  for (int i = 0; i < num_faces; i++) {
    Face f = new Face();
    mesh.faces.add(f);
    
    int j = i + num_vertices + 2;
    words = split (lines[j], " ");
    
    // get the number of vertices for this face
    int nverts = int(words[0]);
    // get all of the vertex indices
    print ("face = ");
    for (int k = 1; k <= nverts; k++) {
      int index = int(words[k]);
      print (index + " ");
      
      // Face and Vertex info
      Vertex v = mesh.vertices.get(index);
      v.one_face = f;
      f.verts.add(v);
      
      // Edge info
      var e = new Edge();
      e.face = f;
      int start_vert_index = (k == 1) ? int(words[nverts]) : int(words[k - 1]);
      e.vert_index = start_vert_index;
      mesh.edges.put(new Pair<Vertex, Vertex>(mesh.vertices.get(start_vert_index), v), e);
    }
    println();
  }

  // Find opposite edges
  for (Face f : mesh.faces) {
    int num_verts = f.verts.size();
    for (int i = 0; i < num_verts; ++i) {
      // opposite edge
      int start_index = (i + 1) % num_verts;
      int end_index = i;
      f.opposites.add(mesh.edges.get(new Pair<Vertex, Vertex>(f.verts.get(start_index), f.verts.get(end_index))));
    }
  }
  
  // Initialize directed edge that will be visiualized
  Face f0 = mesh.faces.get(0);
  displayed_edge = mesh.edges.get(new Pair<Vertex, Vertex>(f0.verts.get(0), f0.verts.get(1)));
  
  return mesh;
}
