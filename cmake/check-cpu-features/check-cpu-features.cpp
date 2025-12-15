#include <llvm/TargetParser/Host.h>
#include <llvm/TargetParser/Triple.h>
#include <llvm/ADT/StringMap.h>
#include <filesystem>
#include <iostream>
#include <fstream>
#include <sstream>

int main() {
    llvm::StringMap<bool> Features;
    std::string CPU = llvm::sys::getHostCPUName().str();
    std::string Triple = llvm::sys::getProcessTriple();
    llvm::Triple TripleObj(Triple);

    // Get the host CPU architecture and build a folder to store the llc-command.txt
    std::string Architecture = TripleObj.getArchName().str();
    std::filesystem::path outDir(Architecture);
    std::filesystem::create_directories(outDir);

    std::ofstream outfile(outDir / "llc-command.txt");

    // Extract the architecture part from the target triple
    std::istringstream TripleStream(Triple);

    if (llvm::sys::getHostCPUFeatures(Features)) {
        std::string Mattributes;
        for (const auto &Feature : Features) {
            Mattributes += (Feature.second ? "+" : "-") + Feature.first().str() + ",";
        }
        // Remove the trailing comma
        if (!Mattributes.empty()) {
            Mattributes.pop_back();
        }

        outfile << "-enable-machine-outliner=never " << "-mcpu=" << CPU << " -mtriple=" << Triple << " -mattr=\"" << Mattributes << "\"" << std::endl;
    } else {
        outfile << "Failed to get host CPU features." << std::endl;
    }

    outfile.close();
    return 0;
}
