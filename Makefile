UNAME_S := $(shell uname -s)
ifeq ($(UNAME_S),Darwin)
  SED_INPLACE := sed -i ''
else
  SED_INPLACE := sed -i
endif

create.project.mssql: check_project_nulity check_app_nulity check_target_existence
	@project_path=$(target)/$(project)_$(app) && \
		cp -r project.tmpl $${project_path} && \
		\
		$(SED_INPLACE) -e 's/SCHEMATIC__PROJECT_NAME/$(project)/g' \
			-e 's/SCHEMATIC__APP_NAME/$(app)/g' \
			-e 's/SCHEMATIC__DB_TYPE/mssql/g' \
			-e 's/SCHEMATIC__BASE_VERSION/$(shell cat VERSION)/g' \
			$${project_path}/docker/make.env/common.env && \
		\
		rm -fr $${project_path}/docker/make.env/psql && \
		rm -fr $${project_path}/docker/deploy/psql && \
		\
		mv $${project_path}/gitignore $${project_path}/.gitignore

create.project.psql: check_project_nulity check_app_nulity check_target_existence
	@project_path=$(target)/$(project)_$(app) && \
		cp -r project.tmpl $${project_path} && \
		\
		$(SED_INPLACE) -e 's/SCHEMATIC__PROJECT_NAME/$(project)/g' \
			-e 's/SCHEMATIC__APP_NAME/$(app)/g' \
			-e 's/SCHEMATIC__DB_TYPE/psql/g' \
			-e 's/SCHEMATIC__BASE_VERSION/$(shell cat VERSION)/g' \
			$${project_path}/docker/make.env/common.env && \
		\
		rm -fr $${project_path}/docker/make.env/mssql && \
		rm -fr $${project_path}/docker/deploy/mssql && \
		\
		mv $${project_path}/gitignore $${project_path}/.gitignore

check_project_nulity:
	@[ -z "$(project)" ] && \
		{ echo "Error! Project is NOT specified."; exit 1; } || \
		exit 0

check_app_nulity:
	@[ -z "$(app)" ] && \
		{ echo "Error! App path is NOT specified."; exit 1; } || \
		exit 0

check_target_nulity:
	@[ -z "$(target)" ] && \
		{ echo "Error! Target path is NOT specified."; exit 1; } || \
		exit 0

check_target_existence: check_target_nulity
	@[ -d $(target)/$(project)_$(app) ] && \
		{ echo "Error! Target path already exists: $(target)/$(project)_$(app)"; exit 1; } || \
		exit 0
