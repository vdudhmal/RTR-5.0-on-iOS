#include "Sphere.h"
#include <cmath>

void Sphere::getSphereVertexData(float spherePositionCoordinates[], float sphereNormalCoordinates[], float sphereTexCoordinates[], unsigned short sphereElements[])
{
    // code
    for (int i = 0; i < 1146; i++)
    {
        model_vertices[i] = spherePositionCoordinates[i];
    }

    for (int i = 0; i < 1146; i++)
    {
        model_normals[i] = sphereNormalCoordinates[i];
    }

    for (int i = 0; i < 764; i++)
    {
        model_textures[i] = sphereTexCoordinates[i];
    }

    for (int i = 0; i < 2280; i++)
    {
        model_elements[i] = sphereElements[i];
    }

    // process sphere's data using sphere header file
    // and accordingly fill our empty arrays
    processSphereData();

    // return processed data to the user by filling his empty array by our filled arrays
    for (int i = 0; i < 1146; i++)
    {
        spherePositionCoordinates[i] = model_vertices[i];
    }

    for (int i = 0; i < 1146; i++)
    {
        sphereNormalCoordinates[i] = model_normals[i];
    }

    for (int i = 0; i < 764; i++)
    {
        sphereTexCoordinates[i] = model_textures[i];
    }

    for (int i = 0; i < 2280; i++)
    {
        sphereElements[i] = model_elements[i];
    }
}

int Sphere::getNumberOfSphereVertices()
{
    // code
    return (numVertices);
}

int Sphere::getNumberOfSphereElements()
{
    // code
    return (numElements);
}

void Sphere::processSphereData()
{
    // code
    int numIndices = 760;
    maxElements = numIndices * 3;

    float vert[3][3]; // position co-ordinates of ONE triangle
    float norm[3][3]; // normal co-ordinates of ONE triangle
    float tex[3][2];  // texture co-ordinates of ONE triangle

    for (int i = 0; i < numIndices; i++)
    {
        for (int j = 0; j < 3; j++)
        {
            vert[j][0] = vertices[indices[i][j]][0];
            vert[j][1] = vertices[indices[i][j]][1];
            vert[j][2] = vertices[indices[i][j]][2];

            norm[j][0] = normals[indices[i][j + 3]][0];
            norm[j][1] = normals[indices[i][j + 3]][1];
            norm[j][2] = normals[indices[i][j + 3]][2];

            tex[j][0] = textures[indices[i][j + 6]][0];
            tex[j][1] = textures[indices[i][j + 6]][1];
        }
        addTriangle(vert, norm, tex);
    }
}

void Sphere::addTriangle(float single_vertex[][3], float single_normal[][3], float single_texture[][2])
{
    // variable declarations
    const float diff = 0.00001f;
    int i, j;

    // code
    // normals should be of unit length
    normalizeVector(single_normal[0]);
    normalizeVector(single_normal[1]);
    normalizeVector(single_normal[2]);

    for (i = 0; i < 3; i++)
    {
        for (j = 0; j < numVertices; j++) // for the first ever iteration of 'j', numVertices will be 0 because of it's initialization in the parameterized constructor
        {
            if (isFoundIdentical(model_vertices[j * 3], single_vertex[i][0], diff) &&
                isFoundIdentical(model_vertices[(j * 3) + 1], single_vertex[i][1], diff) &&
                isFoundIdentical(model_vertices[(j * 3) + 2], single_vertex[i][2], diff) &&

                isFoundIdentical(model_normals[j * 3], single_normal[i][0], diff) &&
                isFoundIdentical(model_normals[(j * 3) + 1], single_normal[i][1], diff) &&
                isFoundIdentical(model_normals[(j * 3) + 2], single_normal[i][2], diff) &&

                isFoundIdentical(model_textures[j * 2], single_texture[i][0], diff) &&
                isFoundIdentical(model_textures[(j * 2) + 1], single_texture[i][1], diff))
            {
                model_elements[numElements] = (short)j;
                numElements++;
                break;
            }
        }

        // If the single vertex, normal and texture do not match with the given, then add the corresponding triangle to the end of the list
        if (j == numVertices && numVertices < maxElements && numElements < maxElements)
        {
            model_vertices[numVertices * 3] = single_vertex[i][0];
            model_vertices[(numVertices * 3) + 1] = single_vertex[i][1];
            model_vertices[(numVertices * 3) + 2] = single_vertex[i][2];

            model_normals[numVertices * 3] = single_normal[i][0];
            model_normals[(numVertices * 3) + 1] = single_normal[i][1];
            model_normals[(numVertices * 3) + 2] = single_normal[i][2];

            model_textures[numVertices * 2] = single_texture[i][0];
            model_textures[(numVertices * 2) + 1] = single_texture[i][1];

            model_elements[numElements] = (short)numVertices; // adding the index to the end of the list of elements/indices
            numElements++;                                    // incrementing the 'end' of the list
            numVertices++;                                    // incrementing count of vertices
        }
    }
}

void Sphere::normalizeVector(float v[])
{
    // code

    // square the vector length
    float squaredVectorLength = (v[0] * v[0]) + (v[1] * v[1]) + (v[2] * v[2]);

    // get square root of above 'squared vector length'
    float squareRootOfSquaredVectorLength = (float)sqrt(squaredVectorLength);

    // scale the vector with 1/squareRootOfSquaredVectorLength
    v[0] = v[0] * 1.0f / squareRootOfSquaredVectorLength;
    v[1] = v[1] * 1.0f / squareRootOfSquaredVectorLength;
    v[2] = v[2] * 1.0f / squareRootOfSquaredVectorLength;
}

bool Sphere::isFoundIdentical(const float val1, const float val2, const float diff)
{
    // code
    if (abs(val1 - val2) < diff)
        return (true);
    else
        return (false);
}
