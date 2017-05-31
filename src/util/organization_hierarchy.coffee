define (require) ->
    { Department } = require 'cs!app/models'

    generateDepartmentDescription: (department) ->
        rootDepartment = department.get('hierarchy')[0]  # city
        unitDepartment = department # unit

        if rootDepartment.organization_type != 'MUNICIPALITY'
            return null

        if unitDepartment.get('organization_type') in [
                'MUNICIPALLY_OWNED_COMPANY', 'MUNICIPAL_ENTERPRISE_GROUP']
            return unitDepartment.getText 'name'

        if unitDepartment.get('organization_type') == 'MUNICIPALITY'

            sectorDepartment = new Department(department.get('hierarchy')[1])

            if unitDepartment.get('level') == 1
                return sectorDepartment.getText('name')

            if department.get('hierarchy').length < 3
                return null

            segmentDepartment = new Department(department.get('hierarchy')[2])

            if (sectorDepartment.get('organization_type') ==
                    segmentDepartment.get('organization_type') == 'MUNICIPALITY')
                return sectorDepartment.getText('name') + ', ' + segmentDepartment.getText('name')
            return sectorDepartment.getText('name')

        return null
