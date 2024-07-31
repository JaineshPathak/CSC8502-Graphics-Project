#include "Skybox.h"
#include "SceneRenderer.h"
#include "AssetManager.h"

#include <nclgl/Shader.h>
#include <nclgl/Camera.h>

Skybox::Skybox()
{
	m_SkyboxShader = AssetManager::Get()->GetShader("SkyboxShader").get();

	const std::string skyboxFilePaths[6]{
		TEXTUREDIR + "rusted_west.jpg",
		TEXTUREDIR + "rusted_east.jpg",
		TEXTUREDIR + "rusted_up.jpg",
		TEXTUREDIR + "rusted_down.jpg",
		TEXTUREDIR + "rusted_south.jpg",
		TEXTUREDIR + "rusted_north.jpg"
	};

	m_SkyboxTex = SOIL_load_OGL_cubemap(
		skyboxFilePaths[0].c_str(), skyboxFilePaths[1].c_str(),
		skyboxFilePaths[2].c_str(), skyboxFilePaths[3].c_str(),
		skyboxFilePaths[4].c_str(), skyboxFilePaths[5].c_str(),
		SOIL_LOAD_RGB, SOIL_CREATE_NEW_ID, 0);
}

Skybox::~Skybox()
{
	glDeleteTextures(1, &m_SkyboxTex);
}

void Skybox::Draw()
{
	if (m_SkyboxShader == nullptr) return;

	glDepthMask(GL_FALSE);

	m_SkyboxShader->Bind();
	m_SkyboxShader->SetTextureCubeMap("cubeTex", m_SkyboxTex, 0);

	SceneRenderer::Get()->GetQuadMesh()->Draw();

	glDepthMask(GL_TRUE);

	m_SkyboxShader->UnBind();
}