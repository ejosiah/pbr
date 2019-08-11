int left(int node) {
	return 2 * node + 1;
}

int right(int node) {
	return 2 * node + 2;
}

int parent(int node) {
return node == 0 ? -1 : (node - 1) / 2;
}

bool isNull(int node) {
	return node < 0 || node >= 9;
}