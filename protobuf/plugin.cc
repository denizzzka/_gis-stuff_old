#include <google/protobuf/compiler/code_generator.h>
#include <google/protobuf/compiler/plugin.h>

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
    return google::protobuf::compiler::PluginMain(argc, argv, &generator);
}
