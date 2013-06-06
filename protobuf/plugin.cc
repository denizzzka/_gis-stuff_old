#include <google/protobuf/compiler/code_generator.h>
#include <google/protobuf/compiler/plugin.h>

using namespace google::protobuf;
using namespace google::protobuf::compiler;
using namespace google::protobuf::internal;

class DCodeGenerator : public compiler::CodeGenerator
{
    virtual bool Generate(const FileDescriptor* file,
                          const string& parameter,
                          compiler::GeneratorContext* context,
                          std::string* error) const;
};

bool DCodeGenerator::Generate(const FileDescriptor* file,
                              const string& parameter,
                              compiler::GeneratorContext* context,
                              std::string* error) const
{
    return false;
}

int main(int argc, char* argv[])
{
    DCodeGenerator generator;
    return google::protobuf::compiler::PluginMain(argc, argv, &generator);
}
