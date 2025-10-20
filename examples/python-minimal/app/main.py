import os

def main():
    project = os.getenv("PROJECT_NAME", "unknown-project")
    app = os.getenv("APP_NAME", "unknown-app")
    print(f"Hello from {project}/{app} (Python)")

if __name__ == "__main__":
    main()

