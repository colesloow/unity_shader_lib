#!/usr/bin/env python3
"""Generate Shader Graph .shadersubgraph assets from specs, mirroring the
hand-authored Fbm2D / Voronoi2D structure (Unity 6000.5 / Shader Graph 17.5).

Usage: gen_subgraphs.py <ShaderGraph/Nodes dir>
Writes <dir>/<Domain>/<Name>.shadersubgraph (+ .meta) and <dir>/<Domain>.meta.
Skips any .shadersubgraph that already exists (editor-authored ones win)."""
import json
import sys
import uuid
from pathlib import Path

NODES_DIR = Path(sys.argv[1])
IMPORTER_SCRIPT_GUID = "60072b568d64c40a485e0fc55012dc9f"

SLOT_CLASS = {"Float": "Vector1MaterialSlot", "Vector2": "Vector2MaterialSlot",
              "Vector3": "Vector3MaterialSlot", "Vector4": "Vector4MaterialSlot"}
PROP_CLASS = {"Float": "Vector1ShaderProperty", "Vector2": "Vector2ShaderProperty",
              "Vector3": "Vector3ShaderProperty", "Vector4": "Vector4ShaderProperty"}


def oid():
    return uuid.uuid4().hex


def vec_value(ptype):
    if ptype == "Float":
        return 0.0
    n = {"Vector2": 2, "Vector3": 3, "Vector4": 4}[ptype]
    return {k: 0.0 for k in "xyzw"[:n]}


def mat_slot(object_id, slot_id, name, slot_type, ptype, shader_out_name=None):
    o = {
        "m_SGVersion": 0,
        "m_Type": f"UnityEditor.ShaderGraph.{SLOT_CLASS[ptype]}",
        "m_ObjectId": object_id,
        "m_Id": slot_id,
        "m_DisplayName": name,
        "m_SlotType": slot_type,  # 0 = input, 1 = output
        "m_Hidden": False,
        "m_HideConnector": False,
        "m_ShaderOutputName": shader_out_name if shader_out_name is not None else name,
        "m_StageCapability": 3,
        "m_CustomBinding": "",
        "m_Value": vec_value(ptype),
        "m_DefaultValue": vec_value(ptype),
        "m_Labels": [],
    }
    if ptype == "Float":
        o["m_LiteralMode"] = False
    return o


def shader_property(object_id, name, ptype):
    o = {
        "m_SGVersion": 1,
        "m_Type": f"UnityEditor.ShaderGraph.Internal.{PROP_CLASS[ptype]}",
        "m_ObjectId": object_id,
        "m_Guid": {"m_GuidSerialized": str(uuid.uuid4())},
        "promotedFromAssetID": "",
        "promotedFromCategoryName": "",
        "promotedOrdering": -1,
        "m_Name": name,
        "m_DefaultRefNameVersion": 1,
        "m_RefNameGeneratedByDisplayName": name,
        "m_DefaultReferenceName": f"_{name}",
        "m_OverrideReferenceName": "",
        "m_GeneratePropertyBlock": True,
        "m_UseCustomSlotLabel": False,
        "m_CustomSlotLabel": "",
        "m_DismissedVersion": 0,
        "m_Precision": 0,
        "overrideHLSLDeclaration": False,
        "hlslDeclarationOverride": 0,
        "hideConnector": False,
        "m_Hidden": False,
        "m_PerRendererData": False,
        "m_customAttributes": [],
    }
    if ptype == "Float":
        o["m_Value"] = 0.0
        o["m_FloatType"] = 0
        o["m_LiteralFloatMode"] = False
        o["m_RangeValues"] = {"x": 0.0, "y": 1.0}
        o["m_SliderType"] = 0
        o["m_SliderPower"] = 3.0
        o["m_EnumType"] = 0
        o["m_CSharpEnumString"] = ""
        o["m_EnumNames"] = ["Default"]
        o["m_EnumValues"] = [0]
    else:
        o["m_Value"] = {k: 0.0 for k in "xyzw"}
    return o


def edge(node_out, slot_out, node_in, slot_in):
    return {
        "m_OutputSlot": {"m_Node": {"m_Id": node_out}, "m_SlotId": slot_out},
        "m_InputSlot": {"m_Node": {"m_Id": node_in}, "m_SlotId": slot_in},
    }


def build(name, category, wrapper_guid, inputs, outputs):
    graph_id, cfn_id, out_node_id, cat_id = oid(), oid(), oid(), oid()

    prop_ids, prop_node_ids = [], []
    prop_objs, prop_node_objs, prop_slot_objs = [], [], []
    for i, (pname, ptype) in enumerate(inputs):
        pid, pnid, psid = oid(), oid(), oid()
        prop_ids.append(pid)
        prop_node_ids.append(pnid)
        prop_objs.append(shader_property(pid, pname, ptype))
        prop_slot_objs.append(mat_slot(psid, 0, pname, 1, ptype, shader_out_name="Out"))
        prop_node_objs.append({
            "m_SGVersion": 0,
            "m_Type": "UnityEditor.ShaderGraph.PropertyNode",
            "m_ObjectId": pnid,
            "m_Group": {"m_Id": ""},
            "m_Name": "Property",
            "m_DrawState": {"m_Expanded": True, "m_Position": {
                "serializedVersion": "2", "x": -600.0, "y": 23.0 + i * 70.0,
                "width": 120.0, "height": 34.0}},
            "m_Slots": [{"m_Id": psid}],
            "synonyms": [],
            "m_Precision": 0,
            "m_PreviewExpanded": True,
            "m_DismissedVersion": 0,
            "m_PreviewMode": 0,
            "m_CustomColors": {"m_SerializableColors": []},
            "m_Property": {"m_Id": pid},
        })

    cfn_slot_objs, cfn_slot_ids = [], []
    for i, (pname, ptype) in enumerate(inputs):
        sid = oid()
        cfn_slot_ids.append(sid)
        cfn_slot_objs.append(mat_slot(sid, i, pname, 0, ptype))
    for j, (oname, otype) in enumerate(outputs):
        sid = oid()
        cfn_slot_ids.append(sid)
        cfn_slot_objs.append(mat_slot(sid, len(inputs) + j, oname, 1, otype))

    cfn_obj = {
        "m_SGVersion": 1,
        "m_Type": "UnityEditor.ShaderGraph.CustomFunctionNode",
        "m_ObjectId": cfn_id,
        "m_Group": {"m_Id": ""},
        "m_Name": f"{name} (Custom Function)",
        "m_DrawState": {"m_Expanded": True, "m_Position": {
            "serializedVersion": "2", "x": -430.0, "y": -17.0, "width": 200.0, "height": 150.0}},
        "m_Slots": [{"m_Id": s} for s in cfn_slot_ids],
        "synonyms": ["code", "HLSL"],
        "m_Precision": 0,
        "m_PreviewExpanded": False,
        "m_DismissedVersion": 0,
        "m_PreviewMode": 0,
        "m_CustomColors": {"m_SerializableColors": []},
        "m_SourceType": 0,
        "m_FunctionName": name,
        "m_FunctionSource": wrapper_guid,
        "m_FunctionSourceUsePragmas": True,
        "m_FunctionBody": "Enter function body here...",
    }

    out_slot_objs, out_slot_ids = [], []
    for j, (oname, otype) in enumerate(outputs):
        sid = oid()
        out_slot_ids.append(sid)
        out_slot_objs.append(mat_slot(sid, j + 1, oname, 0, otype))
    out_node_obj = {
        "m_SGVersion": 0,
        "m_Type": "UnityEditor.ShaderGraph.SubGraphOutputNode",
        "m_ObjectId": out_node_id,
        "m_Group": {"m_Id": ""},
        "m_Name": "Output",
        "m_DrawState": {"m_Expanded": True, "m_Position": {
            "serializedVersion": "2", "x": -180.0, "y": -17.0, "width": 100.0, "height": 100.0}},
        "m_Slots": [{"m_Id": s} for s in out_slot_ids],
        "synonyms": [],
        "m_Precision": 0,
        "m_PreviewExpanded": True,
        "m_DismissedVersion": 0,
        "m_PreviewMode": 0,
        "m_CustomColors": {"m_SerializableColors": []},
        "IsFirstSlotValid": True,
    }

    edges = []
    for i in range(len(inputs)):
        edges.append(edge(prop_node_ids[i], 0, cfn_id, i))
    for j in range(len(outputs)):
        edges.append(edge(cfn_id, len(inputs) + j, out_node_id, j + 1))

    cat_obj = {
        "m_SGVersion": 0,
        "m_Type": "UnityEditor.ShaderGraph.CategoryData",
        "m_ObjectId": cat_id,
        "m_Name": "",
        "m_ChildObjectList": [{"m_Id": p} for p in prop_ids],
    }

    graph_obj = {
        "m_SGVersion": 3,
        "m_Type": "UnityEditor.ShaderGraph.GraphData",
        "m_ObjectId": graph_id,
        "m_Properties": [{"m_Id": p} for p in prop_ids],
        "m_Keywords": [],
        "m_Dropdowns": [],
        "m_CategoryData": [{"m_Id": cat_id}],
        "m_Nodes": [{"m_Id": out_node_id}, {"m_Id": cfn_id}] + [{"m_Id": p} for p in prop_node_ids],
        "m_GroupDatas": [],
        "m_StickyNoteDatas": [],
        "m_Edges": edges,
        "m_VertexContext": {"m_Position": {"x": 0.0, "y": 0.0}, "m_Blocks": []},
        "m_FragmentContext": {"m_Position": {"x": 0.0, "y": 0.0}, "m_Blocks": []},
        "m_PreviewData": {"serializedMesh": {
            "m_SerializedMesh": "{\"mesh\":{\"instanceID\":0}}", "m_Guid": ""}, "preventRotation": False},
        "m_Path": category,
        "m_GraphPrecision": 1,
        "m_PreviewMode": 2,
        "m_OutputNode": {"m_Id": out_node_id},
        "m_SubDatas": [],
        "m_ActiveTargets": [],
    }

    objects = ([graph_obj]
               + out_slot_objs + cfn_slot_objs + prop_slot_objs
               + prop_node_objs + [cat_obj] + prop_objs
               + [out_node_obj, cfn_obj])
    return "\n\n".join(json.dumps(o, indent=4) for o in objects) + "\n"


def asset_meta(guid):
    return (
        "fileFormatVersion: 2\n"
        f"guid: {guid}\n"
        "ScriptedImporter:\n"
        "  internalIDToNameTable: []\n"
        "  externalObjects: {}\n"
        "  serializedVersion: 2\n"
        "  userData: \n"
        "  assetBundleName: \n"
        "  assetBundleVariant: \n"
        f"  script: {{fileID: 11500000, guid: {IMPORTER_SCRIPT_GUID}, type: 3}}\n"
        "  documentationPath: \n"
    )


def folder_meta(guid):
    return (
        "fileFormatVersion: 2\n"
        f"guid: {guid}\n"
        "folderAsset: yes\n"
        "DefaultImporter:\n"
        "  externalObjects: {}\n"
        "  userData: \n"
        "  assetBundleName: \n"
        "  assetBundleVariant: \n"
    )


V1, V2, V3 = "Float", "Vector2", "Vector3"

# (wrapper guid, domain, [ (name, [(in,type)...], [(out,type)...]) ... ])
DOMAINS = [
    ("3b41661afd474bb2bba61efd6ecc026b", "Noise", [
        ("Hash12", [("UV", V2)], [("Out", V1)]),
        ("Hash13", [("P", V3)], [("Out", V1)]),
        ("Hash22", [("P", V2)], [("Out", V2)]),
        ("Hash33", [("P", V3)], [("Out", V3)]),
        ("Fbm", [("P", V3)], [("Out", V1)]),
        ("Fbm2D", [("UV", V2)], [("Out", V1)]),
        ("FbmWarped", [("P", V3), ("WarpAmount", V1)], [("Out", V1)]),
        ("Voronoi2D", [("UV", V2), ("Jitter", V1)], [("F1", V1), ("F2", V1)]),
    ]),
    ("c2d7420bd23e49018f251a22feeac841", "Color", [
        ("Lobe", [("X", V1), ("Mu", V1), ("SigmaLeft", V1), ("SigmaRight", V1)], [("Out", V1)]),
        ("CIE1931", [("Wavelength", V1)], [("XYZ", V3)]),
        ("XYZtoLinearSRGB", [("XYZ", V3)], [("Out", V3)]),
        ("WavelengthToRGB", [("Wavelength", V1)], [("Out", V3)]),
    ]),
    ("d9ac3abf373341e098f8abcf3a7d5c4b", "Optics", [
        ("ThinFilmOPD", [("CosIncidence", V1), ("FilmIndex", V1), ("Thickness", V1)], [("Out", V1)]),
        ("ThinFilmReflectance", [("OpticalPathDiff", V1), ("Wavelength", V1)], [("Out", V1)]),
        ("SpectralFilter", [("OpticalPathDiff", V1)], [("Out", V3)]),
    ]),
    ("a900fbabc4bf42a58fe1f1d8c5ee2ed5", "Lighting", [
        ("DiffuseLambert", [("Normal", V3), ("LightDir", V3)], [("Out", V1)]),
        ("DiffuseWrapped", [("Normal", V3), ("LightDir", V3), ("Wrap", V1)], [("Out", V1)]),
        ("DiffuseOrenNayar", [("Normal", V3), ("LightDir", V3), ("ViewDir", V3), ("Roughness", V1)], [("Out", V1)]),
        ("DistributionGGX", [("NdotH", V1), ("Roughness", V1)], [("Out", V1)]),
        ("GeometrySmithGGX", [("NdotV", V1), ("NdotL", V1), ("Roughness", V1)], [("Out", V1)]),
        ("FresnelSchlickRoughness", [("CosTheta", V1), ("F0", V3), ("Roughness", V1)], [("Out", V3)]),
        ("SpecularCookTorrance", [("Normal", V3), ("ViewDir", V3), ("LightDir", V3), ("F0", V3), ("Roughness", V1)], [("Out", V3)]),
    ]),
    ("d671aadeb57d4f6f9e3b457b1b56de60", "NormalMap", [
        ("NoiseNormal", [("P", V2), ("Epsilon", V1), ("Strength", V1)], [("Out", V3)]),
    ]),
    ("a27e0f0f6f1b46c9b88d4290c0ccab2a", "Easing", [
        ("SmootherStep", [("T", V1)], [("Out", V1)]),
        ("EaseInOutCubic", [("T", V1)], [("Out", V1)]),
        ("EaseOutElastic", [("T", V1)], [("Out", V1)]),
        ("EaseOutBounce", [("T", V1)], [("Out", V1)]),
        ("Gain", [("T", V1), ("K", V1)], [("Out", V1)]),
        ("Pulse", [("Edge0", V1), ("Edge1", V1), ("X", V1)], [("Out", V1)]),
    ]),
    ("7d23c9eee8a0423782413782dee03e62", "SDF", [
        ("SdSphere", [("P", V3), ("Radius", V1)], [("Distance", V1)]),
        ("SdBox", [("P", V3), ("HalfExtents", V3)], [("Distance", V1)]),
        ("SdTorus", [("P", V3), ("MajorRadius", V1), ("MinorRadius", V1)], [("Distance", V1)]),
        ("SdCapsule", [("P", V3), ("PointA", V3), ("PointB", V3), ("Radius", V1)], [("Distance", V1)]),
        ("SdPlane", [("P", V3), ("Normal", V3)], [("Distance", V1)]),
        ("OpUnion", [("A", V1), ("B", V1)], [("Distance", V1)]),
        ("OpSubtract", [("A", V1), ("B", V1)], [("Distance", V1)]),
        ("OpIntersect", [("A", V1), ("B", V1)], [("Distance", V1)]),
        ("Smin", [("A", V1), ("B", V1), ("K", V1)], [("Distance", V1)]),
        ("OpSmoothUnion", [("A", V1), ("B", V1), ("K", V1)], [("Distance", V1)]),
        ("OpSmoothSubtract", [("A", V1), ("B", V1), ("K", V1)], [("Distance", V1)]),
        ("OpSmoothIntersect", [("A", V1), ("B", V1), ("K", V1)], [("Distance", V1)]),
    ]),
]

CATEGORY = "Sub Graphs"  # menu category; a later pass moves these under Coleslow/<Domain>

for wrapper_guid, domain, specs in DOMAINS:
    domain_dir = NODES_DIR / domain
    domain_dir.mkdir(parents=True, exist_ok=True)
    meta_path = NODES_DIR / f"{domain}.meta"
    if not meta_path.exists():
        meta_path.write_text(folder_meta(oid()), encoding="utf-8")
    for name, ins, outs in specs:
        asset_path = domain_dir / f"{name}.shadersubgraph"
        if asset_path.exists():
            print(f"skip {domain}/{name} (exists)")
            continue
        asset_path.write_text(build(name, CATEGORY, wrapper_guid, ins, outs), encoding="utf-8")
        (domain_dir / f"{name}.shadersubgraph.meta").write_text(asset_meta(oid()), encoding="utf-8")
        print(f"wrote {domain}/{name}")
