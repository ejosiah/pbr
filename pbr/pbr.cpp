#define DEBUG

#include <ncl/configured_logger.h>
#include <ncl/gl/GlfwApp.h>
#include "PbrScene.h"

int main()
{
	Resolution res = { 1280, 960 };
	Scene* scene = new PbrScene(res.width, res.height);
	return start(scene);
}
