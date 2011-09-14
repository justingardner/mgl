#ifdef documentation
=========================================================================

     program: mglShader.c
          by: Christopher Broussard
        date: 05/04/06
   copyright: (c) 2006 Justin Gardner, Jonas Larsson (GPL see mgl/COPYING)

$Id: mglShader.c,v 1.9 2007/10/03 17:34:48 justin Exp $
=========================================================================
#endif

/////////////////////////
//   include section   //
/////////////////////////
#include "mgl.h"

// Shader types
typedef enum {
    EVertexShader,
    EFragmentShader,
} EShaderType;

// Function declarations for exposed functions.
void installShaders(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]);
void bindAttribLocation(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]);
void getAttribLocation(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]);
void vertexAttrib(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]);
void linkProgram(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]);
void useProgram(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]);
void getUniformLocation(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]);
void uniform(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]);

// Function declarations for private functions.
int readShaderSource(char *fileName, GLchar **vertexShader, GLchar **fragmentShader);
static int shaderSize(char *fileName, EShaderType shaderType);
static int readShader(char *fileName, EShaderType shaderType, char *shaderText, int size);
int printOglError(char *file, int line);
static void printShaderInfoLog(GLuint shader);
static void printProgramInfoLog(GLuint program);

// Defines
#define printOpenGLError() printOglError(__FILE__, __LINE__)



//////////////
//   main   //
//////////////
void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
	char *command;
	mwSize commandLength;
	
	if (nrhs == 0) {
		usageError("mglShader");
		return;
	}
	
	// Make sure the first argument is a string command.
	if (mxIsChar(prhs[0]) == false) {
		mexPrintf("(mglShader) error : argument 1 must be a command string.\n");
		return;
	}

	// Get the command string.
	commandLength = mxGetN(prhs[0]) + 1;
	command = (char*)mxMalloc(commandLength * sizeof(char));
	if (mxGetString(prhs[0], command, commandLength) == 1) {
		mexPrintf("(mglShader) error : could not retrieve command string.\n");
		return;
	}
	
	// Choose the course of action based on the command string.
	if (strcasecmp("install", command) == 0) {
		installShaders(nlhs, plhs, nrhs, prhs);
	}
	else if (strcasecmp("bindAttribLocation", command) == 0) {
		bindAttribLocation(nlhs, plhs, nrhs, prhs);
	}
	else if (strcasecmp("getAttribLocation", command) == 0) {
		getAttribLocation(nlhs, plhs, nrhs, prhs);
	}
	else if (strcasecmp("vertexAttrib", command) == 0) {
		vertexAttrib(nlhs, plhs, nrhs, prhs);
	}
	else if (strcasecmp("linkProgram", command) == 0) {
		linkProgram(nlhs, plhs, nrhs, prhs);
	}
	else if (strcasecmp("useProgram", command) == 0) {
		useProgram(nlhs, plhs, nrhs, prhs);
	}
	else if (strcasecmp("getUniformLocation", command) == 0) {
		getUniformLocation(nlhs, plhs, nrhs, prhs);
	}
	else if (strcasecmp("uniform", command) == 0) {
		uniform(nlhs, plhs, nrhs, prhs);
	}
	else {
		mexPrintf("(mglShader) warning : unknown command \"%s\"\n", command);
		return;
	}
	
	mxFree(command);
}


void uniform(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
	GLint location;
	mxClassID inputClass;
	size_t m, n;

	// Check the input argument count.
	if (nrhs != 3) {
		mexPrintf("(mglShader) Invalid number of arguments for uniform.\n");
		return;
	}

	// Grab the input arguments.
	location = (GLint)mxGetScalar(prhs[1]);

	// Make sure the variable array has the proper number of elements.
	m = mxGetM(prhs[2]);
	n = mxGetN(prhs[2]);
	if (mxGetNumberOfDimensions(prhs[2]) > 2 || m > 1 || n < 1 || n > 4) {
		mexPrintf("(mglShader) Variable array must have between 1 and 4 elements.\n");
		return;
	}
	
	inputClass = mxGetClassID(prhs[2]);
	if (inputClass == mxDOUBLE_CLASS) {
		double *v = mxGetPr(prhs[2]);

		switch (n)
		{
		case 1:
			glUniform1f(location, (GLfloat)v[0]);
			break;
		case 2:
			glUniform2f(location, (GLfloat)v[0], (GLfloat)v[1]);
			break;
		case 3:
			glUniform3f(location, (GLfloat)v[0], (GLfloat)v[1], (GLfloat)v[2]);
			break;
		case 4:
			glUniform4f(location, (GLfloat)v[0], (GLfloat)v[1], (GLfloat)v[2], (GLfloat)v[3]);
		}
	}
	else if (inputClass == mxINT32_CLASS) {
		int32_t *v = (int32_t*)mxGetData(prhs[2]);

		switch (n)
		{
		case 1:
			glUniform1i(location, (GLint)v[0]);
			break;
		case 2:
			glUniform2i(location, (GLint)v[0], (GLint)v[1]);
			break;
		case 3:
			glUniform3i(location, (GLint)v[0], (GLint)v[1], (GLint)v[2]);
			break;
		case 4:
			glUniform4i(location, (GLint)v[0], (GLint)v[1], (GLint)v[2], (GLint)v[3]);
		}
	}
	else {
		mexPrintf("(mglShader) Only variables of type double or int32 are allowed.\n");
		return;
	}
}


void getUniformLocation(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
	GLuint shaderProg;
	GLint loc;
	char *name;
	mwSize nameLen;

	if (nrhs != 3) {
		mexPrintf("(mglShader) Invalid number of arguments for getUniformLocation.\n");
		return;
	}

	// Extract the input.
	shaderProg = (GLuint)mxGetScalar(prhs[1]);
	nameLen = mxGetN(prhs[2]) + 1;
	name = (char*)mxMalloc(nameLen * sizeof(char));
	mxGetString(prhs[2], name, nameLen);

	// Get the location and return it.
	loc = glGetUniformLocation(shaderProg, (const GLchar*)name);
	plhs[0] = mxCreateDoubleScalar((double)loc);

	mxFree(name);
}


void useProgram(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
	GLuint shaderProg;
	
	if (nrhs != 2) {
		mexPrintf("(mglShader) error: invalid arguments for \"useProgram\"\n");
		return;
	}
	
	shaderProg = (GLuint)mxGetScalar(prhs[1]);
	
	// Install program object as part of current state
    glUseProgram(shaderProg);
}


void linkProgram(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
	GLuint shaderProg;
	GLint linked;
	
	if (nrhs != 2) {
		mexPrintf("(mglShader) error: invalid arguments for \"linkProgram\"\n");
		return;
	}
	
	shaderProg = (GLuint)mxGetScalar(prhs[1]);
	
	// Link the program object and print out the info log
    glLinkProgram(shaderProg);
    printOpenGLError();  // Check for OpenGL errors
    glGetProgramiv(shaderProg, GL_LINK_STATUS, &linked);
    printProgramInfoLog(shaderProg);

    if (!linked) {
        mexPrintf("(mglShader) error: failed to link shader\n");
		return;
	}
}


void vertexAttrib(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
	GLuint index;
	int i;
	double args[4];
	
	if (nrhs < 3 || nrhs > 6) {
		mexPrintf("(mglShader) error: invalid arguments for \"vertexAttrib\"\n");
		return;
	}
	
	// Get the attrib index.
	index = (GLuint)mxGetScalar(prhs[1]);
	
	// Get all values passed to the attrib.
	for (i = 0; i < nrhs - 2; i++) {
		args[i] = mxGetScalar(prhs[2+i]);
	}
	
	switch (nrhs-2) {
		case 1:
			glVertexAttrib1d(index, args[0]);
			break;
		case 2:
			glVertexAttrib2d(index, args[0], args[1]);
			break;
		case 3:
			glVertexAttrib3d(index, args[0], args[1], args[2]);
			break;
		case 4:
			glVertexAttrib4d(index, args[0], args[1], args[2], args[3]);
			break;
	}
	
	printOpenGLError();  // Check for OpenGL errors
}


void getAttribLocation(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
	GLuint program;
	GLchar *name;
	GLint attribLocation;
	int nameLen;
	
	if (nrhs != 3) {
		mexPrintf("(mglShader) error: invalid arguments for \"getAttribLocation\"\n");
		return;
	}
	
	program = (GLuint)mxGetScalar(prhs[1]);
	nameLen = mxGetN(prhs[2]) + 1;
	name = (GLchar*)mxMalloc(nameLen * sizeof(GLchar));
	if (mxGetString(prhs[2], name, nameLen) == 1) {
		mexPrintf("(mglShader) error : could not retrieve \"getAttribLocation\" string.\n");
		return;
	}
	
	attribLocation = glGetAttribLocation(program, (const char*)name);
	
	printOpenGLError();  // Check for OpenGL errors
	
	plhs[0] = mxCreateDoubleScalar((double)attribLocation);
}


void bindAttribLocation(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
	GLuint program, index;
	GLchar *name;
	int nameLen;
	
	if (nrhs != 4) {
		mexPrintf("(mglShader) error : invalid arguments for \"bindAttribLocation\"\n");
		return;
	}
	
	program = (GLuint)mxGetScalar(prhs[1]);
	index = (GLuint)mxGetScalar(prhs[2]);
	nameLen = mxGetN(prhs[3]) + 1;
	name = (GLchar*)mxMalloc(nameLen * sizeof(GLchar));
	if (mxGetString(prhs[3], name, nameLen) == 1) {
		mexPrintf("(mglShader) error : could not retrieve \"bindAttribLocation\" string.\n");
		return;
	}
	
	glBindAttribLocation(program, index, (const GLchar*)name);
	
	printOpenGLError();  // Check for OpenGL errors
}


void installShaders(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
	char *shaderName;
	int shaderNameLength;
	GLchar *VertexShaderSource, *FragmentShaderSource;
	GLuint shaderVS, shaderFS, shaderProg;	// handles to objects
	GLint vertCompiled, fragCompiled;		// status values

	if (nrhs != 2) {
		mexPrintf("(mglShader) error : invalid arguments for \"install\"\n");
		return;
	}
	
	// Make sure the argument is a string.
	if (mxIsChar(prhs[1]) == false) {
		mexPrintf("(mglShader) error : \"install\" argument 1 must be a string.\n");
		return;
	}
	
	// Get the command string.
	shaderNameLength = mxGetN(prhs[1]) + 1;
	shaderName = (char*)mxMalloc(shaderNameLength * sizeof(char));
	if (mxGetString(prhs[1], shaderName, shaderNameLength) == 1) {
		mexPrintf("(mglShader) error : could not retrieve \"install\" shader string.\n");
		return;
	}
	
	// Read the shader source code.
	if (readShaderSource(shaderName, &VertexShaderSource, &FragmentShaderSource) == 0) {
		return;
	}
	
	// Create a vertex shader object and a fragment shader object
    shaderVS = glCreateShader(GL_VERTEX_SHADER);
    shaderFS = glCreateShader(GL_FRAGMENT_SHADER);

    // Load source code strings into shaders

    glShaderSource(shaderVS, 1, (const GLchar**)&VertexShaderSource, NULL);
    glShaderSource(shaderFS, 1, (const GLchar**)&FragmentShaderSource, NULL);

    // Compile the vertex shader, and print out
    // the compiler log file.
    glCompileShader(shaderVS);
    printOpenGLError();  // Check for OpenGL errors
    glGetShaderiv(shaderVS, GL_COMPILE_STATUS, &vertCompiled);
    printShaderInfoLog(shaderVS);

    // Compile the fragment shader, and print out
    // the compiler log file.
    glCompileShader(shaderFS);
    printOpenGLError();  // Check for OpenGL errors
    glGetShaderiv(shaderFS, GL_COMPILE_STATUS, &fragCompiled);
    printShaderInfoLog(shaderFS);

    if (!vertCompiled || !fragCompiled) {
		mexPrintf("(mglShader) error: shaders failed to compile\n");
        return;
	}

    // Create a program object and attach the two compiled shaders
    shaderProg = glCreateProgram();
    glAttachShader(shaderProg, shaderVS);
    glAttachShader(shaderProg, shaderFS);
	
	plhs[0] = mxCreateDoubleScalar((double)shaderProg);
}


int readShaderSource(char *fileName, GLchar **vertexShader, GLchar **fragmentShader)
{
	int vSize, fSize;

    // Allocate memory to hold the source of our shaders.
    vSize = shaderSize(fileName, EVertexShader);
    fSize = shaderSize(fileName, EFragmentShader);
	
    if ((vSize == -1) || (fSize == -1)) {
        mexPrintf("(mglShader) error : cannot determine size of the shader %s\n", fileName);
        return 0;
    }

    *vertexShader = (GLchar *) malloc(vSize);
    *fragmentShader = (GLchar *) malloc(fSize);

    // Read the source code
    if (!readShader(fileName, EVertexShader, *vertexShader, vSize)) {
        mexPrintf("Cannot read the file %s.vert\n", fileName);
        return 0;
    }

    if (!readShader(fileName, EFragmentShader, *fragmentShader, fSize)) {
        mexPrintf("Cannot read the file %s.frag\n", fileName);
        return 0;
    }

    return 1;
}


static int shaderSize(char *fileName, EShaderType shaderType)
{
    //
    // Returns the size in bytes of the shader fileName.
    // If an error occurred, it returns -1.
    //
    // File name convention:
    //
    // <fileName>.vert
    // <fileName>.frag
    //
    int fd, keepReading = 1, count = 0;
    char name[256], buf[256];
#ifdef _WIN32
	int readCount;
#else
	ssize_t readCount;
#endif

	// Create the full name of the shader.
    strcpy(name, fileName);
    switch (shaderType)
    {
        case EVertexShader:
            strcat(name, ".vert");
            break;
        case EFragmentShader:
            strcat(name, ".frag");
            break;
        default:
            mexPrintf("ERROR: unknown shader file type\n");
            exit(1);
            break;
    }
	
	mexPrintf("filename: %s\n", name);

    // Open the file, and find its length.  lseek kept screwing up, doing it this way seems to work.
#ifdef _WIN32
	if (_sopen_s(&fd, (const char*)name, _O_RDONLY, _SH_DENYNO, _S_IREAD | _S_IWRITE) != 0) {
		mexPrintf("Failed to open shader file.");
		return -1;
	}
#else
    fd = open((const char*)name, O_RDONLY);
#endif
	while (keepReading) {
#ifdef _WIN32
		readCount = _read(fd, buf, 256);
#else
		readCount = read(fd, buf, 256);
#endif
		if (readCount == 0) {
			keepReading = 0;
		}
		else if (readCount == -1) {
			mexPrintf("Error reading file\n");
			return -1;
		}
		
		count += readCount;
	}
#ifdef _WIN32
	_close(fd);
#else
	close(fd);
#endif
	
    return count;
}



static int readShader(char *fileName, EShaderType shaderType, char *shaderText, int size)
{
    //
    // Reads a shader from the supplied file and returns the shader in the
    // arrays passed in. Returns 1 if successful, 0 if an error occurred.
    // The parameter size is an upper limit of the amount of bytes to read.
    // It is ok for it to be too big.
    //
    FILE *fh;
    char name[100];
    int count;

    strcpy(name, fileName);

    switch (shaderType) 
    {
        case EVertexShader:
            strcat(name, ".vert");
            break;
        case EFragmentShader:
            strcat(name, ".frag");
            break;
        default:
            mexPrintf("ERROR: unknown shader file type\n");
            exit(1);
            break;
    }

    //
    // Open the file
    //
    fh = fopen(name, "r");
    if (!fh)
        return -1;

    //
    // Get the shader from a file.
    //
    fseek(fh, 0, SEEK_SET);
    count = (int) fread(shaderText, 1, size, fh);
    shaderText[count] = '\0';

    if (ferror(fh))
        count = 0;

    fclose(fh);
    return count;
}


int printOglError(char *file, int line)
{
    //
    // Returns 1 if an OpenGL error occurred, 0 otherwise.
    //
    GLenum glErr;
    int    retCode = 0;

    glErr = glGetError();
    while (glErr != GL_NO_ERROR)
    {
        mexPrintf("glError in file %s @ line %d: %s\n", file, line, gluErrorString(glErr));
        retCode = 1;
        glErr = glGetError();
    }
    return retCode;
}


//
// Print out the information log for a shader object
//
static void printShaderInfoLog(GLuint shader)
{
    GLint infologLength = 0;
    GLsizei charsWritten  = 0;
    GLchar *infoLog;

    printOpenGLError();  // Check for OpenGL errors

    glGetShaderiv(shader, GL_INFO_LOG_LENGTH, &infologLength);

    printOpenGLError();  // Check for OpenGL errors

    if (infologLength > 0) {
        infoLog = (GLchar*)mxMalloc(infologLength);
        if (infoLog == NULL)
        {
            mexPrintf("ERROR: Could not allocate InfoLog buffer\n");
			return;
        }
        glGetShaderInfoLog(shader, infologLength, &charsWritten, infoLog);
        mexPrintf("Shader InfoLog:\n%s\n\n", infoLog);
        mxFree(infoLog);
    }
    printOpenGLError();  // Check for OpenGL errors
}


//
// Print out the information log for a program object
//
static void printProgramInfoLog(GLuint program)
{
    GLint infologLength = 0;
    GLsizei charsWritten  = 0;
    GLchar *infoLog;

    printOpenGLError();  // Check for OpenGL errors

    glGetProgramiv(program, GL_INFO_LOG_LENGTH, &infologLength);

    printOpenGLError();  // Check for OpenGL errors

    if (infologLength > 0)
    {
        infoLog = (GLchar *)mxMalloc(infologLength);
        if (infoLog == NULL)
        {
            mexPrintf("ERROR: Could not allocate InfoLog buffer\n");
            return;
        }
        glGetProgramInfoLog(program, infologLength, &charsWritten, infoLog);
        mexPrintf("Program InfoLog:\n%s\n\n", infoLog);
        mxFree(infoLog);
    }
    printOpenGLError();  // Check for OpenGL errors
}
