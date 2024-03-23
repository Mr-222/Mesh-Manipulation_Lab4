// Read polygon mesh from .ply file
//
// You should modify this routine to store all of the mesh data
// into a mesh data structure instead of printing it to the screen.

import java.util.Random;

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
    
    Edge e_start = this.edgeFromVertex(v);
    Edge e = e_start;
    do {
      Face f = e.face;
      n.add(f.calculateNormal());
      
      e = this.swing(e);
    } while (e != e_start);
    
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
  
  public Mesh applyNoise() {
    ArrayList<Float> noises = new ArrayList<>(this.vertices.size());
    Random rand = new Random();
    for (int i = 0; i < this.vertices.size(); ++i)
      noises.add(rand.nextFloat() * .2f - .1f);
    
    ArrayList<PVector> new_vertices = new ArrayList<>();
    ArrayList<ArrayList<Integer>> new_faces = new ArrayList<>();    
    HashMap<PVector, Integer> vertex_index = new HashMap<>();
    
    for (Face f : this.faces) {
      ArrayList<Integer> curr_face = new ArrayList<>();
      
      for (Vertex v : f.verts) {
        PVector v_pos = new PVector(v.x, v.y, v.z);
        
        if (vertex_index.containsKey(v_pos))
          curr_face.add(vertex_index.get(v_pos));
        else {
          curr_face.add(new_vertices.size());
          vertex_index.put(v_pos.copy(), new_vertices.size());
          
          PVector n = this.calculateVertexNormal(v);
          n.mult(noises.get(new_vertices.size()));
          v_pos.add(n);
          
          new_vertices.add(v_pos);
        }
      }
      
      new_faces.add(curr_face);
    }
    
    return new Mesh(new_vertices, new_faces);
  }
  
  public Mesh shrink(float lambda) {
    ArrayList<PVector> new_vertices = new ArrayList<>();
    ArrayList<ArrayList<Integer>> new_faces = new ArrayList<>();    
    HashMap<PVector, Integer> vertex_index = new HashMap<>();    
    
    for (Face f : this.faces) {
      ArrayList<Integer> curr_face = new ArrayList<>();
      
      for (Vertex v : f.verts) {
        PVector v_pos = new PVector(v.x, v.y, v.z);
        
        if (vertex_index.containsKey(v_pos))
          curr_face.add(vertex_index.get(v_pos));
        else {
          curr_face.add(new_vertices.size());
          vertex_index.put(v_pos.copy(), new_vertices.size());          
          
          PVector v_cent = new PVector(0, 0, 0);
          Edge e_start = this.edgeFromVertex(v);
          Edge e = e_start;
          float neighbor_edges_count = 0;
          do {
            neighbor_edges_count += 1f;
            
            int local_index = e.face.verts.indexOf(v);
            Vertex curr_v = e.face.verts.get( (local_index + 1) % e.face.verts.size() );
            v_cent.add(new PVector(curr_v.x, curr_v.y, curr_v.z));
            
            e = this.swing(e);
          } while (e != e_start);
          
          v_cent.div(neighbor_edges_count);
          PVector delta_v = PVector.sub(v_cent, v_pos);
          delta_v.mult(lambda);
          
          new_vertices.add(PVector.add(v_pos, delta_v));
        }
      }
      
      new_faces.add(curr_face);
    }
    
    return new Mesh(new_vertices, new_faces);
  }
  
  private Mesh inflate(float miu) {
    return this.shrink(miu);
  }
  
  public Mesh laplacian(float lambda) {
    Mesh mesh = this;
    for (int i = 0; i < 40; ++i)
      mesh = mesh.shrink(lambda);
      
    return mesh;
  }
  
  public Mesh taubin(float lambda, float miu) {
    Mesh mesh = this;
    for (int i = 0; i < 40; ++i) {
      mesh = mesh.shrink(lambda);
      mesh = mesh.inflate(miu);
    }
    
    return mesh;
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
  
  public Mesh midPointSubdivide() {
    ArrayList<PVector> new_vertices = new ArrayList<>();
    HashMap<PVector, Integer> new_vertices_index = new HashMap<>();
    ArrayList<ArrayList<Integer>> new_faces = new ArrayList<>();    
    
    // For each old face, Midpoint subdivision would create e(number of face's edges) new faces
    for (Face f : this.faces) {
      ArrayList<Integer> midpoints_indices = new ArrayList<>(f.verts.size()); // We need to record this info to create inner face
      
      PVector prev_mid_pos = new PVector(0.0, 0.0, 0.0); // For creating new face
      for (int i = 0; i < f.verts.size(); ++i) {
        Vertex start = f.verts.get(i);
        Vertex end = f.verts.get( (i + 1) % f.verts.size() );
        
        PVector start_pos = new PVector(start.x, start.y, start.z);
        PVector end_pos = new PVector(end.x, end.y, end.z);
        PVector mid_pos = linearInterp(start_pos, end_pos, 0.5f).normalize(); // Project mid point to unit sphere
        
        if (!new_vertices_index.containsKey(start_pos)) {
          new_vertices_index.put(start_pos, new_vertices.size());
          new_vertices.add(start_pos);
        }
        if (!new_vertices_index.containsKey(mid_pos)) {
          new_vertices_index.put(mid_pos, new_vertices.size());
          new_vertices.add(mid_pos);
        }
        
        midpoints_indices.add(new_vertices_index.get(mid_pos));
        
        // We don't have full information for creating the first face for now
        if (i > 0) {
          // Create counter-clockwise face, this face is a triangle
          ArrayList<Integer> curr_face = new ArrayList<>(3);
          curr_face.add(new_vertices_index.get(start_pos));
          curr_face.add(new_vertices_index.get(mid_pos));
          curr_face.add(new_vertices_index.get(prev_mid_pos));
          new_faces.add(curr_face);
        }
        
        prev_mid_pos = mid_pos;
      }
      
      // Now we can go back and create the first face
      Vertex start = f.verts.get(0);
      Vertex end = f.verts.get(1);
      
      PVector start_pos = new PVector(start.x, start.y, start.z);
      PVector end_pos = new PVector(end.x, end.y, end.z);
      PVector mid_pos = linearInterp(start_pos, end_pos, 0.5f).normalize(); // Project mid point to unit sphere
      
      ArrayList<Integer> curr_face = new ArrayList<>(3);
      curr_face.add(new_vertices_index.get(start_pos));
      curr_face.add(new_vertices_index.get(mid_pos));
      curr_face.add(new_vertices_index.get(prev_mid_pos));    
      new_faces.add(curr_face);
      
      // Inner face
      new_faces.add(midpoints_indices);
    }
    
    return new Mesh(new_vertices, new_faces);
  }
  
  public Mesh catmullSubdivide() {
    HashMap<Face, PVector> face_points = new HashMap<>();
    HashMap<Edge, PVector> edge_points = new HashMap<>();
    HashMap<Vertex, PVector> point_points = new HashMap<>();
    
    // Face points
    for (Face f : this.faces) {
      PVector face_point = f.centroid();
      face_points.put(f, face_point);
    }
   
    // Edge points
    for (Face f : this.faces) {
      // For each edge
      for (int i = 0; i < f.verts.size(); ++i) {
        PVector edge_point = new PVector(0, 0, 0);
        
        Vertex v1 = f.verts.get(i);
        Vertex v2 = f.verts.get( (i + 1) % f.verts.size() );
        
        Edge e = this.edges.get(new Pair<Vertex, Vertex>(v1, v2));
        Edge inv_e = this.edges.get(new Pair<Vertex, Vertex>(v2, v1));
        assert(inv_e != null);
        Face opposite_f = inv_e.face;
        
        edge_point.add(new PVector(v1.x, v1.y, v1.z));
        edge_point.add(new PVector(v2.x, v2.y, v2.z));
        edge_point.add(face_points.get(f));
        edge_point.add(face_points.get(opposite_f));
        edge_point.div(4f);
        
        edge_points.put(e, edge_point);
        edge_points.put(inv_e, edge_point);
      }
    }
    
    // Move old points
    for (Vertex v : this.vertices) {
      PVector E = new PVector(0, 0, 0);
      PVector F = new PVector(0, 0, 0);
        
      Edge e_start = this.edgeFromVertex(v);
      Edge e = e_start;
      float neighbor_edges_count = 0;
      do {
        neighbor_edges_count += 1f;
          
        PVector edge_point = edge_points.get(e);
        E.add(new PVector(edge_point.x, edge_point.y, edge_point.z));
          
        PVector face_point = face_points.get(e.face);
        F.add(new PVector(face_point.x, face_point.y, face_point.z));
          
        e = this.swing(e);
      } while (e != e_start);
        
      E.div(neighbor_edges_count);
      E.mult(2f);
      F.div(neighbor_edges_count);
      PVector V = new PVector(v.x, v.y, v.z);
      V.mult(neighbor_edges_count - 3f);
        
      PVector point_point = PVector.add(E, F);
      point_point.add(V);
      point_point.div(neighbor_edges_count);
        
      point_points.put(v, point_point);
    }
    
    // Form faces
    ArrayList<PVector> new_vertices = new ArrayList<>();
    HashMap<PVector, Integer> vertex_index = new HashMap<>();
    ArrayList<ArrayList<Integer>> new_faces = new ArrayList<>();
    
    for (Face f : this.faces) {
      for (int i = 0; i < f.verts.size(); ++i) {
        ArrayList<Integer> curr_face = new ArrayList<>();
        
        Vertex v = f.verts.get(i);
        Vertex next_v = f.verts.get( (i + 1) % f.verts.size() );
        Vertex prev_v = f.verts.get( (i == 0) ? f.verts.size() - 1 : i - 1 ); 
        
        PVector point_point = point_points.get(v);
        if (vertex_index.containsKey(point_point))
          curr_face.add(vertex_index.get(point_point));
        else {
          curr_face.add(new_vertices.size());
          vertex_index.put(point_point, new_vertices.size());
          new_vertices.add(point_point);
        }
        
        PVector edge_point_1 = edge_points.get(this.edges.get(new Pair<Vertex, Vertex>(v, next_v)));
        if (vertex_index.containsKey(edge_point_1))
          curr_face.add(vertex_index.get(edge_point_1));
        else {
          curr_face.add(new_vertices.size());
          vertex_index.put(edge_point_1, new_vertices.size());
          new_vertices.add(edge_point_1);
        }
        
        PVector face_point = face_points.get(f);
        if (vertex_index.containsKey(face_point))
          curr_face.add(vertex_index.get(face_point));
        else {
          curr_face.add(new_vertices.size());
          vertex_index.put(face_point, new_vertices.size());
          new_vertices.add(face_point);
        }
        
        PVector edge_point_2 = edge_points.get(this.edges.get(new Pair<Vertex, Vertex>(prev_v, v)));
        if (vertex_index.containsKey(edge_point_2))
          curr_face.add(vertex_index.get(edge_point_2));
        else {
          curr_face.add(new_vertices.size());
          vertex_index.put(edge_point_2, new_vertices.size());
          new_vertices.add(edge_point_2);
        }
        
        new_faces.add(curr_face);
      }
    }
    
    return new Mesh(new_vertices, new_faces);
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
