# Include configuration
include config.env
export $(shell sed 's/=.*//' config.env)

.PHONY: build rebase update help clean

help:
	@echo "Available targets:"
	@echo "  build   - Build the container image locally"
	@echo "  rebase  - Build and rebase to the local image"
	@echo "  update  - Update to latest generated image"
	@echo "  clean   - Remove build artifacts"

build:
	@echo "Building container image: $(TARGET_IMAGE_NAME)..."
	@./build.sh

rebase: build
	@echo "Rebasing to local image: $(TARGET_IMAGE_NAME)..."
	rpm-ostree rebase ostree-unverified-image:oci-archive:/tmp/$(TARGET_IMAGE_NAME).tar.gz

update:
	@echo "Updating to latest local image..."
	rpm-ostree update

clean:
	@echo "Cleaning up..."
	@rm -f /tmp/$(TARGET_IMAGE_NAME).tar.gz
	@echo "Done."

