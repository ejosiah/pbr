#pragma ignore(on)
uniform int numTriangles;

struct Triangle {
	vec3 a;
	vec3 b;
	vec3 c;
	int objectToWorldId;
	int worldToObjectId;
	int id;
};

struct Ray {
	vec3 o;
	vec3 d;
	float tMax;
	float time;
	//	Medium medium;

		// Ray differentials
	bool hasDefferntials;
	vec3 rxo, ryo;
	vec3 rxd, ryd;

};

struct HitInfo {
	float t;
	int shape;
	int id;
	vec4 extras;
};

struct Box {
	vec3 min;
	vec3 max;
};

struct BVHNode {
	Box box;
	int splitAxis;
	int id;
	int offset;
	int size;
	int isLeaf;
	int child[2];
};

#pragma ignore(off)

const int ROOT = 0;
const int LEFT = 0;
const int RIGHT = 1;
const float INFINITY = 1.0 / 0.0;


bool hasNoVolume(Box box) {
	return all(equal(box.min, vec3(0))) && all(equal(box.max, vec3(0)));
}

bool intersectBox(Ray ray, Box box) {
	if (hasNoVolume(box)) return false;
	vec3   tMin = (box.min - ray.o) / ray.d;
	vec3   tMax = (box.max - ray.o) / ray.d;
	vec3     t1 = min(tMin, tMax);
	vec3     t2 = max(tMin, tMax);
	float tNear = max(max(t1.x, t1.y), t1.z);
	float  tFar = min(min(t2.x, t2.y), t2.z);
	return  tNear < ray.tMax || tNear < tFar;
}

bool isLeaf(BVHNode node) {
	return node.isLeaf == 1;
}

bool hasChild(BVHNode node, int id) {
	return node.child[id] != -1;
}

BVHNode getNode(int id) {
	if (id >= 0 && id < numNodes) return bvh[id];
	
	BVHNode nullNode;
	nullNode.box.min = nullNode.box.max = vec3(0);
	nullNode.child[LEFT] = nullNode.child[RIGHT] = -1;
	nullNode.isLeaf = 1;
	nullNode.id = -1;
	nullNode.size = nullNode.offset = 0;
	return nullNode;
}

bool intersect(Ray ray, int offset, int size, out HitInfo hit) {
	hit.t = ray.tMax;

	for (int i = 0; i < size; i++) {
		int tid = index[offset + i];
		float t, u, v, w;
		Triangle tri;
		fetchTriangle(tid, tri);
		if (triangleRayIntersect(ray, tri, t, u, v, w)) {
			if (t < hit.t) {
				hit.t = t;
				hit.shape = TRIANGLE;
				hit.id = tid;
				hit.extras = vec4(u, v, w, 0);
			}
		}
	}
	return hit.t != ray.tMax;
}

bool negativeDir(Ray ray, int axis) {
	return (1 / ray.d[axis]) < 0;
}


bool intersectsTriangle(Ray ray, out HitInfo hit) {
	HitInfo lHit;

	bool aHit = false;
	int toVisitOffset = 0, currentNodeIndex = 0;
	int nodesToVisit[64];

	while (!aHit) {
		BVHNode node = getNode(currentNodeIndex);
		if (intersectCube(ray, node.box, lHit)) {
			if (isLeaf(node)) {
				if (intersect(ray, node.offset, node.size, lHit)) aHit = true;
				
				if (toVisitOffset == 0) break;
				currentNodeIndex = nodesToVisit[--toVisitOffset];
			}
			else {
				if (negativeDir(ray, node.splitAxis)) {
					nodesToVisit[toVisitOffset++] = node.child[LEFT];
					currentNodeIndex = node.child[RIGHT];
				}
				else {
					nodesToVisit[toVisitOffset++] = node.child[RIGHT];
					currentNodeIndex = node.child[LEFT];
				}
			}
		}
		else {
			if (toVisitOffset == 0) break;
			currentNodeIndex = nodesToVisit[--toVisitOffset];
		}
	}
	hit = lHit;
	return aHit;
}

void fetchTriangle(int id, out Triangle tri) {
	if (fetchFromTexture) {
		int v0 = id * 3;
		int v1 = id * 3 + 1;
		int v2 = id * 3 + 2;

		tri.a = texelFetch(triangles, v0).xyz;
		tri.b = texelFetch(triangles, v1).xyz;
		tri.c = texelFetch(triangles, v2).xyz;
	}
	else {
		tri = triangle[id];
	}
}

void fetchShading(int id, out Triangle tri, out Shading s) {
	if (fetchFromTexture) {
		int v0 = id * 3;
		int v1 = id * 3 + 1;
		int v2 = id * 3 + 2;

		tri.a = texelFetch(triangles, v0).xyz;
		tri.b = texelFetch(triangles, v1).xyz;
		tri.c = texelFetch(triangles, v2).xyz;

		s.n0 = texelFetch(normals, v0).xyz;
		s.n1 = texelFetch(normals, v1).xyz;
		s.n2 = texelFetch(normals, v2).xyz;

		s.uv0 = texelFetch(uvs, v0).xy;
		s.uv1 = texelFetch(uvs, v1).xy;
		s.uv2 = texelFetch(uvs, v1).xy;
	}
	else {
		tri = triangle[id];
		s = shading[id];
	}
}

bool triangleRayIntersect(Ray ray, Triangle tri, out float t, out float u, out float v, out float w) {
	vec3 ba = tri.b - tri.a;
	vec3 ca = tri.c - tri.a;
	vec3 pa = ray.o - tri.a;
	vec3 pq = -ray.d;

	vec3 n = cross(ba, ca);
	float d = dot(pq, n);

	if (d <= 0) return false; // ray is either coplainar with triangle abc or facing opposite it

	t = dot(pa, n);

	if (t < 0) return false;     // ray invariant t >= 0

	vec3 e = cross(pq, pa);

	v = dot(e, ca);
	if (v < 0.0f || v > d) return false;

	w = -dot(e, ba);
	if (w < 0.0f || (v + w) > d) return false;

	float ood = 1.0 / d;

	t *= ood;
	v *= ood;
	w *= ood;
	u = 1 - v - w;

	return true;
}