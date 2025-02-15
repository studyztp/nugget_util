#include <llvm/TargetParser/Host.h>
#include <llvm/ADT/StringMap.h>
#include <iostream>
#include <fstream>

int main() {
    llvm::StringMap<bool> Features;
    std::ofstream outfile("cpu_features.txt");

    if (llvm::sys::getHostCPUFeatures(Features)) {
        for (const auto &Feature : Features) {
            outfile << (Feature.second ? "+" : "-") << Feature.first().str() << ",";
        }
    } else {
        outfile << "Failed to get host CPU features." << std::endl;
    }

    outfile.close();
    return 0;
}