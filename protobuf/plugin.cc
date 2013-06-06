#include <google/protobuf/compiler/code_generator.h>

using namespace google::protobuf;

class DCodeGenerator : public compiler::CodeGenerator
{
    virtual bool Generate(const FileDescriptor*, const string&, compiler::GeneratorContext*, std::string*) const
    {
        return 1;
    }
};

int main(int argc, char* argv[])
{
    DCodeGenerator generator;
    return 0;
    //return PluginMain(argc, argv, &generator);
}
