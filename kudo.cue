package mysql

operator <Name>: {
	name:    string | *Name
	version: string
	image:   string
    replicas: int | *1
    kind: string | *"deployment"
	I = image
	expose port <N>:         int
    P = expose.port
	expose password <value>: string

	command: string | *""

	volume <VolumeName>: {
		name:      string | *VolumeName
		mountPath: string
		subPath:   string | *null
		readOnly:  *false | true
		kubernetes: {}
	}


	task <TaskName>: {
		image: string | *I
        expose port <N>: int
        _expose: bool | *true
        command: [...]
		ports: [ {
			name:          k
			containerPort: v
		} for k, v in P if len(expose.port) == 0 && len(P) > 0 && _expose == true]
	}

	task "\(Name)": {}

	plan <PlanName>: {
		strategy: "serial" | *"parallel"
		phase <PhaseName>: {} | *{
			strategy: "serial" | *"parallel"
			tasks:    *[...]
		}

	}

	plan deploy: {} | {
		phase "\(Name)": {
            tasks: [...] | *["\(Name)", ...]
        }
	}
}

kubernetes deployments: {
	"\(k)": (_k8sSpec & {X: x}).X.kubernetes & {
		apiVersion: "extensions/v1beta1"
		kind:       "Deployment"
		spec replicas: x.replicas
	} for k, x in operator if x.kind == "deployment"
}

_k8sSpec X kubernetes: {
	metadata name: X.name
	//metadata labels component: X.label.component
	spec template: {
		//metadata labels: X.label
		spec containers: [{
			name:  X.name
			image: X.image
			//args:  X.args
			//env:   [ {name: k} & v for k, v in X.envSpec ] if len(X.envSpec) > 0
			ports: [ {
				name:          k
				containerPort: p
			} for k, p in X.expose.port ]
		}]
	}
	// Volumes
	spec template spec: {
		volumes: [
				v.kubernetes & {name: v.name} for v in X.volume
		] if len(X.volume) > 0
		containers: [{
			// TODO: using conversions this would look like:
			// volumeMounts: [ k8s.VolumeMount(v) for v in d.volume ]
			volumeMounts: [ {
				name:      v.name
				mountPath: v.mountPath
				subPath:   v.subPath if v.subPath != null | true
				readOnly:  v.readOnly if v.readOnly
			} for v in X.volume
			] if len(X.volume) > 0
		}]
	}
}