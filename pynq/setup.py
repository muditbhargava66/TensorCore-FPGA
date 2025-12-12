"""
TensorCore-FPGA PYNQ Package Setup
"""

from setuptools import setup, find_packages

setup(
    name="tensorcore",
    version="1.0.0",
    description="PYNQ driver for TensorCore LLM accelerator",
    author="TensorCore-FPGA Contributors",
    license="Apache-2.0",
    packages=find_packages(),
    install_requires=[
        "pynq>=2.6",
        "numpy>=1.19",
    ],
    python_requires=">=3.10",
    classifiers=[
        "Development Status :: 4 - Beta",
        "Intended Audience :: Developers",
        "License :: OSI Approved :: Apache Software License",
        "Programming Language :: Python :: 3",
        "Topic :: Scientific/Engineering :: Artificial Intelligence",
    ],
)
