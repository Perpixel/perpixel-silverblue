# Include configuration
include config.env
export $(shell sed 's/=.*//' config.env)

.PHONY: container rebase update help clean

help:
	@echo "Available targets:"
	@echo "  container   - Build the container image locally"
	@echo "  rebase  - Build and rebase to the local image"
	@echo "  update  - Update to latest generated image"
	@echo "  clean   - Remove build artifacts"

container:
	@echo "Building container image: $(TARGET_IMAGE_NAME)..."
	@./build.sh

rebase:
	@echo "Rebasing to local image: $(TARGET_IMAGE_NAME)..."
	# rpm-ostree rebase ostree-unverified-image:oci-archive:/tmp/$(TARGET_IMAGE_NAME).tar.gz
	bootc switch ostree-unverified-image:oci-archive:/tmp/$(TARGET_IMAGE_NAME).tar.gz

update:
	@echo "Updating to latest local image..."
	# rpm-ostree update
	bootc update

clean:
	@echo "Cleaning up..."
	@rm -f /tmp/$(TARGET_IMAGE_NAME).tar.gz
	@echo "Done."

