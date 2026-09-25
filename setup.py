from setuptools import setup, find_packages

setup(
    name="jack-telephony-agent",
    version="2.0.0",
    py_modules=["main", "server"],
    packages=find_packages(),
)
