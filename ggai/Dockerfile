#  author  : Jeong Han Lee
#  email   : jeonghan.lee@gmail.com
#  version : 0.0.3
##
FROM python:3.12-slim
# Use ARG for metadata and build-time configuration
ARG BUILD_DATE
ARG BUILD_VERSION
ARG TZ=America/Los_Angeles

# Set labels for metadata
LABEL maintainer="Jeong Han Lee <jeonghan.lee@gmail.com>"
LABEL org.label-schema.schema-version="1.0"
LABEL org.label-schema.build-date=$BUILD_DATE
LABEL org.label-schema.name="jeonghanlee/ggai"
LABEL org.label-schema.description="Google Generative AI Environment (for CI and Interactive use)"
LABEL org.label-schema.url="https://github.com/jeonghanlee/Dockerfiles/"
LABEL org.label-schema.version=$BUILD_VERSION
LABEL org.label-schema.docker.cmd="docker run -it --rm --name=ggai jeonghanlee/ggai"

# Set the timezone environment variable
ENV TZ=${TZ}

# Set up the timezone system-wide. This is a separate layer for better caching.
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

# Security Best Practice: Create a non-root user
RUN groupadd --gid 1001 ggaigroup && \
    useradd --uid 1001 --gid ggaigroup --shell /bin/bash --create-home ggaiuser

# --- Install Dependencies Directly via Command Line ---
# The backslash (\) is used to continue the command on the next line for readability.
RUN pip install --no-cache-dir \
    google-generativeai \
    python-gitlab \
    langchain \
    langchain_google_genai \
    langchain_community \
    chromadb \
    pypdf

# Switch to the non-root user for security
USER appuser

# Set a working directory for the user
WORKDIR /home/ggaiuser
# --- For Interactive Use ---
# Set the default shell to Bash for a better interactive experience
SHELL ["/bin/bash", "-c"]
# Set the default command to launch a Bash shell if no other command is provided
CMD ["/bin/bash"]

