# Licensed to the Apache Software Foundation (ASF) under one
# or more contributor license agreements.  See the NOTICE file
# distributed with this work for additional information
# regarding copyright ownership.  The ASF licenses this file
# to you under the Apache License, Version 2.0 (the
# "License"); you may not use this file except in compliance
# with the License.  You may obtain a copy of the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing,
# software distributed under the License is distributed on an
# "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
# KIND, either express or implied.  See the License for the
# specific language governing permissions and limitations
# under the License.

# Install airflow using regular 'pip install' command. This install airflow depending on the arguments:
# AIRFLOW_INSTALLATION_METHOD - determines where to install airflow form:
#             "." - installs airflow from local sources
#             "apache-airflow" - installs airflow from PyPI 'apache-airflow' package
# AIRFLOW_VERSION_SPECIFICATION - optional specification for Airflow version to install (
#                                 might be ==2.0.2 for example or <3.0.0
# UPGRADE_TO_NEWER_DEPENDENCIES - determines whether eager-upgrade should be performed with the
#                                 dependencies (with EAGER_UPGRADE_ADDITIONAL_REQUIREMENTS added)
#
# shellcheck shell=bash disable=SC2086
# shellcheck source=scripts/docker/common.sh
. "$( dirname "${BASH_SOURCE[0]}" )/common.sh"

: "${AIRFLOW_PIP_VERSION:?Should be set}"

function install_airflow() {
    # Coherence check for editable installation mode.
    if [[ ${AIRFLOW_INSTALLATION_METHOD} != "." && \
          ${AIRFLOW_INSTALL_EDITABLE_FLAG} == "--editable" ]]; then
        echo
        echo "${COLOR_RED}ERROR! You can only use --editable flag when installing airflow from sources!${COLOR_RESET}"
        echo "{COLOR_RED}       Current installation method is '${AIRFLOW_INSTALLATION_METHOD} and should be '.'${COLOR_RESET}"
        exit 1
    fi
    # Remove mysql from extras if client is not going to be installed
    if [[ ${INSTALL_MYSQL_CLIENT} != "true" ]]; then
        AIRFLOW_EXTRAS=${AIRFLOW_EXTRAS/mysql,}
    fi
    if [[ "${UPGRADE_TO_NEWER_DEPENDENCIES}" != "false" ]]; then
        echo
        echo "${COLOR_BLUE}Installing all packages with eager upgrade${COLOR_RESET}"
        echo
        # eager upgrade
        pip install --upgrade --upgrade-strategy eager \
            "${AIRFLOW_INSTALLATION_METHOD}[${AIRFLOW_EXTRAS}]${AIRFLOW_VERSION_SPECIFICATION}" \
            ${EAGER_UPGRADE_ADDITIONAL_REQUIREMENTS}
        if [[ -n "${AIRFLOW_INSTALL_EDITABLE_FLAG}" ]]; then
            # Remove airflow and reinstall it using editable flag
            # We can only do it when we install airflow from sources
            pip uninstall apache-airflow --yes
            pip install ${AIRFLOW_INSTALL_EDITABLE_FLAG} \
                "${AIRFLOW_INSTALLATION_METHOD}[${AIRFLOW_EXTRAS}]${AIRFLOW_VERSION_SPECIFICATION}"
        fi

        # make sure correct PIP version is used
        pip install --disable-pip-version-check "pip==${AIRFLOW_PIP_VERSION}"
        echo
        echo "${COLOR_BLUE}Running 'pip check'${COLOR_RESET}"
        echo
        pip check
    else \
        echo
        echo "${COLOR_BLUE}Installing all packages with constraints and upgrade if needed${COLOR_RESET}"
        echo
        pip install ${AIRFLOW_INSTALL_EDITABLE_FLAG} \
            "${AIRFLOW_INSTALLATION_METHOD}[${AIRFLOW_EXTRAS}]${AIRFLOW_VERSION_SPECIFICATION}" \
            --constraint "${AIRFLOW_CONSTRAINTS_LOCATION}"
        # make sure correct PIP version is used
        pip install --disable-pip-version-check "pip==${AIRFLOW_PIP_VERSION}"
        # then upgrade if needed without using constraints to account for new limits in setup.py
        pip install --upgrade --upgrade-strategy only-if-needed \
            ${AIRFLOW_INSTALL_EDITABLE_FLAG} \
            "${AIRFLOW_INSTALLATION_METHOD}[${AIRFLOW_EXTRAS}]${AIRFLOW_VERSION_SPECIFICATION}"
        # make sure correct PIP version is used
        pip install --disable-pip-version-check "pip==${AIRFLOW_PIP_VERSION}"
        echo
        echo "${COLOR_BLUE}Running 'pip check'${COLOR_RESET}"
        echo
        pip check
    fi

}

common::get_colors
common::get_airflow_version_specification
common::override_pip_version_if_needed
common::get_constraints_location
common::show_pip_version_and_location

install_airflow
