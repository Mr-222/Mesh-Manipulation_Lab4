class Vertex {
  public float x, y, z;
  public Face one_face;
}

class Face {
  public ArrayList<Vertex> verts;
  public ArrayList<Edge> opposites;
  
  public Face() {
    verts = new ArrayList<>();
    opposites = new ArrayList<>();
  }
  
  public PVector calculateNormal() {
    Vertex v0 = verts.get(0);
    Vertex v1 = verts.get(1);
    Vertex v2 = verts.get(2);
    
    var v0v1 = new PVector(v1.x - v0.x, v1.y - v0.y, v1.z - v0.z);
    var v0v2 = new PVector(v2.x - v0.x, v2.y - v0.y, v2.z - v0.z);
    
    PVector n = v0v1.cross(v0v2).normalize();
    return n;
  }
  
  public PVector centroid() {
    var centroid_pos = new PVector(0, 0, 0);
    for (Vertex v : verts)
      centroid_pos.add(new PVector(v.x, v.y, v.z));
    centroid_pos.div(verts.size());
    
    return centroid_pos;
  }
}

class Edge {
  public Face face;
  public int vert_index;
}
